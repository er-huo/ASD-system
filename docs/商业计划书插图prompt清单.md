# 商业计划书插图 Prompt 清单

本文件用于单独管理 `latex/showcase-body.tex` 中各处占位图对应的图片生成提示词，避免把 prompt 直接写进商业计划书正文。

当前版本已经按最新版商业计划书结构同步，和 `latex/showcase-body.tex` 中的占位图一一对应。

## 统一风格基线

建议所有插图统一采用以下视觉方向：

- 温暖、低刺激、克制而有陪伴感
- 森林、浅木色、柔和晨光、微弱星点、自然留白
- 轻绘本感与说明书感结合，既有情绪温度，也保留商业计划书所需的清晰度
- 数据元素只作为轻量提示，不做强烈科技 HUD，不做冰冷赛博风
- 尊重 ASD 儿童语境，避免“被治疗对象化”的姿态，避免过度煽情
- 人物表情温和、动作舒展、构图稳定，不使用高刺激对比和拥挤信息

可复用的统一风格模板：

```text
warm low-stimulation illustration for an autism-support business plan, gentle forest palette, warm beige, sage green, soft amber, natural morning light, respectful and caring tone, child-friendly companion robot, picture-book softness with clean presentation layout, subtle data cues, soft edges, quiet emotional atmosphere, no harsh contrast, no cyberpunk, no medicalized cold feeling, no crowded composition
```

## 使用边界

- 插图服务于商业计划书叙事，不宜画成纯产品原型图或纯技术架构图。
- 当前系统已经落地的事实可以表现：儿童训练、伙伴机器人、训练总结、治疗师看板、摄像头辅助识别。
- 当前未完全落地的能力不要画成既成事实：语音情绪识别、生理信号手环、复杂多模态硬件部署。
- 如果要画“结构图”，也优先以产品闭环、角色关系、使用流程为主，而不是堆技术名词。

## 插图列表

### 1. 执行摘要主视觉

对应位置：第一章《执行摘要》

```text
warm low-stimulation illustration for an autism-support business plan, gentle forest palette, warm beige, sage green, soft amber, natural morning light, respectful and caring tone, child-friendly companion robot, picture-book softness with clean presentation layout, subtle data cues, soft edges, quiet emotional atmosphere, no harsh contrast, no cyberpunk, no medicalized cold feeling, no crowded composition, a child sitting calmly with a tablet during emotion training, a rounded friendly companion robot nearby, soft silhouettes of a parent and therapist in the background, atmosphere of being understood and gently accompanied, cover-quality composition, stable and hopeful
```

### 2. 场景痛点图

对应位置：第二章《项目缘起与真实需求》

```text
warm low-stimulation illustration for an autism-support business plan, split scene showing the real difficulties around an ASD child, one side a parent accompanying a child at home with visible fatigue but gentle patience, one side a therapist guiding a child in a calm rehabilitation classroom, soft floating icons representing emotion understanding, communication, records and continuity, forest-toned handbook style, warm and restrained, respectful, no dramatic suffering, no crowded layout
```

### 3. 竞争定位图

对应位置：第三章《市场机会与竞争判断》

```text
gentle strategic positioning infographic for an autism-support business plan, warm beige and sage green palette with muted amber highlights, clean two-axis layout, one axis professional support depth, one axis companionship and child-friendliness, soft rounded markers for research prototypes, general children apps, institutional tools, and StarTalk, subtle leaf textures and calm empty space, business-plan clarity with warm tone, low stimulation, not too technical
```

### 4. 活动路径图

对应位置：第四章《产品方案与现阶段基础》

```text
warm picture-book style learning path for an autism-support business plan, a soft forest trail connecting five activity stations, each station represents one training activity: emotion detective, matching, face building, social story, mood diary, a gentle companion robot guiding a child forward, progression from recognition to understanding to expression, layered but uncluttered composition, warm green, beige and muted amber palette, calm and encouraging mood
```

### 5. 产品闭环图

对应位置：第四章《产品方案与现阶段基础》

```text
warm explanatory infographic for an autism-support business plan, showing a gentle product loop rather than a cold tech diagram, child training interaction, camera-assisted emotion observation, adaptive hints and pacing, session summary, therapist dashboard, all connected in a calm circular flow, rounded cards, leaf-like connectors, soft forest textures, readable business-plan composition, restrained data visuals, trustworthy and clear
```

### 6. 试点流程图

对应位置：第六章《商业落地与实施路径》

```text
warm roadmap illustration for an autism-support business plan, four-stage pilot flow: scenario onboarding, guided use, training sessions, review and feedback, icons of child, parent, therapist and dashboard, handbook-like layout, low-stimulation educational illustration, steady and reliable feeling, warm forest palette, clear sequence, no aggressive startup style
```

### 7. 技术亮点逻辑图

对应位置：第五章《技术亮点与核心支撑》

```text
warm explanatory infographic for an autism-support business plan, a gentle technical support loop showing mastery tracking, emotion-state observation, rule-based adaptive hinting, difficulty adjustment, session summary and therapist review, soft circular or flowing structure, forest palette, warm beige, sage green and soft amber, child-centered and respectful, subtle data markers, clear but not cold, no futuristic HUD, no hard-edged engineering blueprint
```

### 8. 团队协作图

对应位置：第八章《团队力量与未来展望》

```text
supportive collaboration illustration for an autism-support business plan, a calm network showing product planning, frontend experience, backend and data, content and field testing, plus external therapists and partner institutions, a softly glowing central StarTalk symbol, rounded relationship map, warm and trustworthy tone, like the final page of a caring project handbook, clean and stable composition
```

## 可选补充图

以下内容不在当前 `latex/showcase-body.tex` 占位图中，但如果后续用于答辩 PPT、封底或章节页，可以继续沿用。

### A. 商业合作路径图

```text
gentle business roadmap for an autism-support project, prototype validation to institutional pilot cooperation to standardized service to family extension, growth-ring or path-like composition, warm restrained palette, gradual trustworthy expansion instead of aggressive growth, clean business-plan infographic
```

### B. 风险与边界提示图

```text
low-stimulation handbook-style infographic for an autism-support project, three to four calm cards for product fit, implementation challenge, privacy boundary, long-term trust, warm neutral palette, stable and reassuring visual language, no alarmist style
```

## 使用建议

- 如果用于正文插图，优先保持统一画风、统一配色和统一留白比例。
- 如果用于答辩 PPT，可在此基础上适度增强信息层级，但不要转向强科技感或强商业海报风。
- 如果后续改用真实系统截图，可保留这些 prompt 用于封面图、章节页和信息示意图。
- 若需要批量生成，建议所有 prompt 都保留统一风格模板，并只替换场景主体，避免整本计划书插画风格飘散。
