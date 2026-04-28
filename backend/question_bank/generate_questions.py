import json
from pathlib import Path

EMOTIONS = ["happy", "sad", "angry", "fear", "surprise", "neutral", "confused"]
N_PER_SLOT = 3

L1_CHOICES = {"happy":["happy","sad"],"sad":["happy","sad"],"angry":["angry","neutral"],"fear":["fear","neutral"],"surprise":["happy","surprise"],"neutral":["happy","neutral"],"confused":["confused","neutral"]}
L2_CHOICES = {"happy":["happy","sad","angry"],"sad":["happy","sad","fear"],"angry":["angry","sad","neutral"],"fear":["fear","angry","neutral"],"surprise":["happy","surprise","neutral"],"neutral":["happy","sad","neutral"],"confused":["confused","neutral","sad"]}
L3_CHOICES = {"happy":["happy","sad","angry","neutral"],"sad":["happy","sad","fear","neutral"],"angry":["angry","sad","fear","neutral"],"fear":["fear","angry","surprise","neutral"],"surprise":["happy","surprise","neutral","confused"],"neutral":["happy","sad","neutral","confused"],"confused":["confused","neutral","sad","fear"]}

def make_detective():
    q = []
    for emotion in EMOTIONS:
        for level,(choices,stype,ptmpl) in enumerate([(L1_CHOICES[emotion],"image","assets/images/pcs/{emotion}_{n:02d}.png"),(L2_CHOICES[emotion],"image","assets/images/photos/{emotion}_{n:02d}.jpg"),(L3_CHOICES[emotion],"video","assets/videos/{emotion}_{n:02d}.mp4")],start=1):
            for n in range(1,N_PER_SLOT+1):
                q.append({"id":f"detective_{emotion}_l{level}_{n:03d}","activity_type":"detective","emotion_target":emotion,"difficulty_level":level,"stimuli_type":stype,"stimuli_path":ptmpl.format(emotion=emotion,n=n),"choices":choices,"correct_answer":emotion})
    return q

def make_match():
    q = []
    for emotion in EMOTIONS:
        for level,(choices,n_pairs) in enumerate([(L1_CHOICES[emotion],1),(L2_CHOICES[emotion],2),(L3_CHOICES[emotion],3)],start=1):
            for n in range(1,N_PER_SLOT+1):
                q.append({"id":f"match_{emotion}_l{level}_{n:03d}","activity_type":"match","emotion_target":emotion,"difficulty_level":level,"stimuli_type":"image" if level<3 else "composite","stimuli_path":f"assets/images/photos/{emotion}_{n:02d}.jpg","choices":choices,"correct_answer":emotion,"n_pairs":n_pairs})
    return q

def make_face_build():
    EL={1:["eyes","mouth"],2:["eyes","eyebrows","mouth"],3:["eyes","eyebrows","mouth","eye_outline"]}
    q = []
    for emotion in EMOTIONS:
        for level in [1,2,3]:
            choices=L1_CHOICES[emotion] if level==1 else(L2_CHOICES[emotion] if level==2 else L3_CHOICES[emotion])
            for n in range(1,N_PER_SLOT+1):
                q.append({"id":f"face_build_{emotion}_l{level}_{n:03d}","activity_type":"face_build","emotion_target":emotion,"difficulty_level":level,"stimuli_type":"composite","stimuli_path":f"assets/face_parts/{emotion}/set_{n:02d}","choices":choices,"correct_answer":emotion,"elements":EL[level]})
    return q

def make_social():
    SC={"happy":"小明收到了生日礼物","sad":"小明的气球飞走了","angry":"小明的积木被推倒了","fear":"小明在黑暗中找不到妈妈","surprise":"小明打开了神秘的盒子","neutral":"小明在安静地看书","confused":"小明看着复杂的地图"}
    q = []
    for emotion in EMOTIONS:
        for level in [1,2,3]:
            choices=L1_CHOICES[emotion] if level==1 else(L2_CHOICES[emotion] if level==2 else L3_CHOICES[emotion])
            for n in range(1,N_PER_SLOT+1):
                q.append({"id":f"social_{emotion}_l{level}_{n:03d}","activity_type":"social","emotion_target":emotion,"difficulty_level":level,"stimuli_type":"video","stimuli_path":f"assets/videos/social/{emotion}_{n:02d}.mp4","choices":choices,"correct_answer":emotion,"scenario":SC[emotion],"question_text":"视频里的小明现在是什么心情？"})
    return q

if __name__=="__main__":
    out_dir=Path(__file__).parent
    for name,fn in [("detective",make_detective),("match",make_match),("face_build",make_face_build),("social",make_social)]:
        data=fn()
        (out_dir/f"{name}.json").write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding="utf-8")
        print(f"{name}.json: {len(data)} questions")
