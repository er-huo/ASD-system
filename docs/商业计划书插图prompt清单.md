# 商业计划书插图 Prompt 清单

本文件用于单独管理 `latex/showcase-body.tex` 中各处占位图对应的图片生成提示词，避免把 prompt 直接写进商业计划书正文。

当前版本已经按最新版商业计划书结构同步，和 `latex/showcase-body.tex` 中的占位图一一对应。

## 统一风格基线

建议所有插图统一采用以下视觉方向：

- 温暖、低刺激、克制而有陪伴感
- 森林、浅木色、柔和晨光、微弱星点、自然留白
- 轻绘本感与信息图感结合，既有情绪温度，也保留商业计划书所需的清晰度
- 数据元素只作为轻量提示，不做强烈科技 HUD，不做冰冷赛博风
- 尊重 ASD 儿童语境，避免“被治疗对象化”的姿态，避免过度煽情
- 人物表情温和、动作舒展、构图稳定，不使用高刺激对比和拥挤信息
- 优先采用卡片式、分栏式、流程式、矩阵式等可读性更强的版式，而不是纯场景叙事插画

## 图形表达原则

- 每张图优先只表达一个核心结论，用 3--5 个模块完成信息拆解。
- 优先使用框、卡片、分区、编号、箭头、连接线来表达逻辑关系。
- 可以保留少量人物或场景元素提供温度，但人物不应压过信息结构本身。
- 图中应预留标题条、注释栏、短句说明区，便于后续在 LaTeX 或 PPT 中补中文文字。
- 不建议让模型直接生成大段中文正文；更适合生成“有文字位置的图”，后续人工覆盖说明。

可复用的统一风格模板：

```text
warm low-stimulation semi-infographic for an autism-support business plan, gentle forest palette, warm beige, sage green, soft amber, natural morning light, respectful and caring tone, child-friendly companion robot, picture-book softness combined with clear information design, modular card layout, clean sections, arrows and connectors, title bars and caption areas reserved for later text overlay, subtle data cues, soft edges, quiet emotional atmosphere, readable hierarchy, no harsh contrast, no cyberpunk, no medicalized cold feeling, no crowded composition
```

## 使用边界

- 插图服务于商业计划书叙事，不宜画成纯产品原型图或纯技术架构图。
- 当前系统已经落地的事实可以表现：儿童训练、伙伴机器人、训练总结、治疗师看板、摄像头辅助识别。
- 当前未完全落地的能力不要画成既成事实：语音情绪识别、生理信号手环、复杂多模态硬件部署。
- 如果要画“结构图”，也优先以产品闭环、角色关系、使用流程为主，而不是堆技术名词。

## 插图列表

### 0. 封面主视觉

对应位置：封面页

```text
warm low-stimulation cover illustration for an autism-support business plan, gentle forest path at dawn, small child seen from behind and a friendly companion robot walking side by side toward soft starlight, respectful and hopeful, no visible close-up face, no text, no watermark, composition weighted to the lower half with generous calm negative space above, warm beige sage green soft amber palette, picture-book softness, subtle stars, quiet and trustworthy atmosphere
```

当前成品文件：

- `latex/assets/cover-illustration-base.png`
- `latex/assets/cover-illustration.png`

### 1. 执行摘要总览图

对应位置：第一章《执行摘要》

```text
warm low-stimulation semi-infographic for an autism-support business plan, executive-summary overview page with five structured modules, module 1 project positioning, module 2 product and system, module 3 market and business path, module 4 social value, module 5 current progress and next steps, clear top title band, balanced grid or dashboard layout, each module in a soft framed card with icon and short caption area, light connector lines showing one coherent story, small child and companion robot element only as emotional anchor, warm forest palette, picture-book softness combined with business-plan readability, reserved whitespace for later Chinese annotations, clear hierarchy, calm and trustworthy, no crowded composition
```

当前成品文件：

- `latex/assets/executive-summary-overview-v3-base.png`
- `latex/assets/executive-summary-overview-v6-cn.png`

### 2. 第二章训练现场痛点图

对应位置：第二章《项目缘起与真实需求》

```text
warm low-stimulation infographic for an autism-support business plan, three framed pain-point cards in a clean horizontal layout, card 1 family accompaniment burden, card 2 institution training pressure and transfer difficulty, card 3 lack of continuous records and coordination, each card with a clear icon or small scene, top title bars, short caption box under each card, gentle arrows or a shared bottom consequence strip can be used, warm beige sage green muted amber palette, picture-book softness combined with business-plan readability, no child face close-up, no dramatic suffering, no crowded narrative composition, leave clean title strips and caption areas for exact Chinese overlay, logical, calm, respectful and easy to understand at a glance
```

本次实际生成补充说明：

- 生成策略：先生成无有效正文文字的底图，再本地覆盖准确中文，避免模型输出“占位字”或错字。
- 中文覆盖内容：
  - 标题：家庭陪伴压力、机构训练压力、记录与协同断点
  - 说明：
    - 家庭陪伴压力：长期陪伴投入高 / 居家练习难持续 / 变化不易被看见
    - 机构训练压力：优质干预依赖人力 / 材料向真实场景迁移难 / 训练节奏难稳定复制
    - 记录与协同断点：家庭机构各看一段 / 缺少连续过程记录 / 难形成共同判断
- 当前成品文件：
  - `latex/assets/chapter2-pain-points-base.png`
  - `latex/assets/chapter2-pain-points-cn.png`

### 3. 竞争定位图

对应位置：第三章《市场机会与竞争判断》

```text
warm comparison-style positioning infographic for an autism-support business plan, centered hero card for StarTalk surrounded by three competitor cards, competitor card 1 research prototypes, competitor card 2 general children emotion apps, competitor card 3 institutional support tools, each competitor card uses only 2 to 3 concise feature tags, center StarTalk card highlights three clear advantages low-stimulation training, readable training process, supporter collaboration, soft arrows or contrast lines pointing toward the center, calm modular layout, picture-book softness combined with business-plan clarity, warm beige sage green muted amber palette, clean title bars and caption areas reserved for exact Chinese overlay, no crowded narrative scene, no dramatic characters, clear comparison hierarchy, trustworthy and easy to understand at a glance
```

当前建议：

- 第三章这一张图更适合做“竞争定位图”，而不是章节总览图。
- 更合适的形式是“中心定位卡 + 外围三类竞品对照卡”：
  - 中间放“星语灵境”
  - 周围放“研究型原型”“大众儿童情绪/教育应用”“机构辅助工具”
  - 中间卡片只突出三项核心差异：低刺激训练、过程可读、支持者协同
- 这样比“市场进入 + 竞品分类 + 定位”三块拼盘图更聚焦，也更符合第三章 `3.3` 的文字内容。
- 本图已按当前正文版本生成并插入 LaTeX。
- 当前成品文件：
  - `latex/assets/chapter3-positioning-v2-base.png`
  - `latex/assets/chapter3-positioning-v5-cn.png`

建议后续中文覆盖文字：

- 图题：竞争定位与差异化优势
- 三类竞品：
  - 研究型原型：方法基础强 / 产品化不足
  - 大众儿童应用：易上手 / 场景适配浅
  - 机构辅助工具：贴近专业 / 儿童端闭环弱
- 中心定位：
  - 星语灵境
  - 低刺激训练
  - 过程可读
  - 支持者协同

### 4. 活动协同图

对应位置：第四章《产品方案与现阶段基础》

```text
warm low-stimulation semi-infographic collaboration map for an autism-support business plan, one centered rounded collaboration hub plus five equal activity cards around it, balanced non-linear layout, not a timeline, not a staircase, not a left-to-right journey, no inter-card arrows, only soft connector lines from the center hub to each card to express flexible switching and mutual support, each card must have a blank top title tab and a large blank inner safe area for later Chinese overlay, cards represent emotion detective, expression matching, face building, social story, mood diary, three small floating thematic tags for recognition understanding expression may appear lightly around the hub but must not imply stages, warm beige sage green muted amber palette, picture-book softness combined with business-plan readability, tiny companion robot only as a corner decoration, no text, no placeholder text, no watermark, calm, clear and easy to understand at a glance
```

补充说明：

- 第四章目前新增了一张“五层系统框架图”，更适合直接用 LaTeX 原生结构图实现，而不是生成式图片。
- 因为这类图最重要的是文字准确、逻辑稳定和层级清楚，所以当前不建议用插画方式替代。
- 本次实际生成策略：先生成无正文文字底图，再本地覆盖准确中文，避免模型输出错字或占位字。
- 当前版式要求：中心枢纽 + 五张并列活动卡，明确表达“围绕同一训练目标、可按状态灵活切换”；不使用串联箭头，不制造单一路径误解。
- 文字统一放在卡片或中心框的内部安全区域，不压住主体图形；每张卡片至少预留一块可容纳“标题 + 两行说明”的中文区域。
- 当前成品文件：
  - `latex/assets/chapter4-activity-path-v2-base.png`
  - `latex/assets/chapter4-activity-path-v2-cn.png`

### 5. 产品 Demo 展示图

对应位置：第四章《产品方案与现阶段基础》

```text
warm product-demo collage for an autism-support business plan, four-panel layout showing a real product walkthrough, panel 1 child home screen with five activity cards, panel 2 training screen with companion robot emotion interaction and camera status area, panel 3 session summary screen with gentle chart and completion feedback, panel 4 therapist dashboard with accuracy, mastery and session records, clean device-frame or screen-card presentation, calm business-plan readability, low-stimulation forest palette, warm beige sage green soft amber accents, realistic UI demonstration feeling rather than narrative illustration, clear title bands and short caption zones reserved for exact Chinese overlay, no crowded decoration, trustworthy and easy to understand
```

当前建议：

- 这一张图最好优先使用真实系统截图拼接，而不是完全依赖生成式图片。
- 如果后续需要生成示意图，也应尽量做成“产品四联屏展示”，而不是抽象概念图。
- 建议后续中文覆盖文字：
  - 首页进入
  - 训练互动
  - 训练总结
  - 治疗师看板

### 6. 第六章试点落地路径图

对应位置：第六章《商业落地与实施路径》

- 建议图题：`图6-1 试点落地路径示意图`
- 图面目标：不要画成大场景插画，而是做成结构清楚的四阶段路径信息图，既温和，又能一眼读懂试点推进逻辑。

```text
warm structured semi-infographic for an autism-support business plan, four-stage pilot implementation roadmap as four tall vertical cards in one left-to-right sequence, handbook-like layout, each card has a top icon badge, a colored title band, a large clean inner text area, and a small footer panel for one short evaluation focus, clear arrows only between adjacent stages, no center hub, no 2x2 loop, no dramatic narrative scene, warm forest palette with beige moss green muted orange, gentle paper texture, calm business-plan readability, suitable for later exact Chinese overlay

stage 1 card: scenario onboarding, icon of clipboard and setup checklist, emphasis on target children range, equipment conditions, role and process alignment
stage 2 card: familiarization and trial use, icon of child and companion interaction, emphasis on rhythm adaptation, interface familiarity, basic operation
stage 3 card: formal training, icon of activity module and response signals, emphasis on participation, prompt frequency, completion and switching feeling
stage 4 card: review and iteration, icon of dashboard and magnifier, emphasis on co-reading results, problem list, refinement of question bank interface and workflow

leave enough blank margin for Chinese titles and 2 to 3 short lines inside each card, plus one concise footer sentence per card, no placeholder text, no text overlapping icons, overall look should feel gentle, trustworthy, sequential, and easy to understand at a glance
```

建议中文覆盖文字：

- 01 场景接入
- 明确适用范围
- 确认设备条件
- 理清角色与流程
- 先回答能否顺利接入
- 02 熟悉与试运行
- 熟悉伙伴形象
- 适应页面节奏
- 完成基础操作
- 重点看是否愿意进入
- 03 正式训练
- 观察参与情况
- 记录提示频次
- 回看完成率与切换感受
- 看机制是在帮助还是添负担
- 04 回看与迭代
- 家长与治疗师共读
- 沉淀问题清单
- 回到题库界面与流程修正
- 把试点反馈快速带回下一轮修正
- 本次实际生成策略：先生成无正文文字底图，再本地覆盖准确中文，保证四阶段标签完整可读。
- 当前版式要求：整体采用“四张竖卡 + 顺序箭头”的阶段路径图，不做中心控制框，也不做叙事插画；每张卡片同时表达“这一阶段做什么”和“这一阶段重点验证什么”。
- 文字保持精简，不遮挡卡片主体中的图标和结构元素；标题、正文和底部判断语都必须留在各自框内。
- 当前成品文件：
  - `latex/assets/chapter6-pilot-roadmap-base.png`
  - `latex/assets/chapter6-pilot-roadmap-v2-cn.png`

### 7. 第五章机制图补充说明

对应位置：第五章《关键机制与技术支撑》

当前建议：

- 第五章三张机制图已经生成并插入正文。
- 当前已生成文件：
  - `latex/assets/chapter5-adaptive-base.png`
  - `latex/assets/chapter5-adaptive-cn.png`
  - `latex/assets/chapter5-feedback-base.png`
  - `latex/assets/chapter5-feedback-cn.png`
  - `latex/assets/chapter5-data-loop-base.png`
  - `latex/assets/chapter5-data-loop-cn.png`
- 这一章的图仍然要保持温和风格，但比起叙事情绪，更要突出机制关系和结构可读性。
- 当前建议配置三张机制图：
  - 自适应训练机制图
  - 温和反馈机制图
  - 训练数据闭环图
- 图面形式优先选择卡片、箭头、分区、闭环，不建议画成纯场景插画。

#### 7.1 自适应训练机制图

```text
warm logic-first mechanism infographic for an autism-support business plan, structured top-center-bottom flow, top row has four input cards mastery tracking, recent answers, response time, camera emotion stream, center card is rule-based adaptive engine, bottom row has four action cards hint, reduce difficulty, raise difficulty, scene change, clean arrows, rounded cards, soft forest palette, clear caption bars, calm handbook-like readability, no crowded narrative scene, no futuristic interface, precise and trustworthy
```

建议后续中文覆盖文字：

- 输入信号：BKT掌握度、最近作答、反应时长、摄像头情绪流
- 中央模块：规则引擎
- 输出动作：提示、降难、升难、切换场景

#### 7.2 温和反馈机制图

```text
warm explanatory feedback infographic for an autism-support business plan, top row shows three trigger states correct answer, wrong answer, confused state, center card shows gentle feedback orchestration, bottom row shows four response channels emotion audio, companion robot color and motion, hint card, stable low-stimulation layout, clean modular arrows, low stimulation forest palette, respectful child-centered tone, clear and readable at a glance, not overly narrative
```

建议后续中文覆盖文字：

- 触发状态：答对、答错、困惑
- 中央模块：反馈编排
- 输出通道：情绪音频、机器人颜色与动作、提示卡片、固定布局与低刺激节奏

#### 7.3 训练数据闭环图

```text
warm closed-loop data infographic for an autism-support business plan, five connected modules in one cycle child training, session records, emotion logs and mastery update, summary and dashboard review, next-round training focus, soft arrows forming one loop, simple icon language, warm beige sage green muted amber palette, handbook-like structure, calm and trustworthy, strong logic clarity, no decorative clutter
```

建议后续中文覆盖文字：

- 儿童端训练
- 会话记录
- 情绪日志与掌握度更新
- 总结页与看板
- 下一轮训练重点

### 8. 团队协作图

对应位置：第八章《团队力量与未来展望》

```text
supportive collaboration infographic for an autism-support business plan, central project node with two surrounding layers, inner layer shows product planning, frontend experience, backend and data, content and field testing, outer layer shows therapists and partner institutions, clear connecting lines with small label areas, rounded relationship map, warm and trustworthy tone, like the final page of a caring project handbook, clean stable composition, structured rather than decorative
```

## 可选补充图

以下内容不在当前 `latex/showcase-body.tex` 占位图中，但如果后续用于答辩 PPT、封底或章节页，可以继续沿用。

### A. 商业合作路径图

```text
gentle business roadmap infographic for an autism-support project, four staged blocks from prototype validation to institutional pilot cooperation to standardized service to family extension, soft upward path or growth-ring composition, each stage with one icon and one caption area, warm restrained palette, gradual trustworthy expansion instead of aggressive growth, clean business-plan infographic
```

### B. 风险与边界提示图

```text
low-stimulation handbook-style infographic for an autism-support project, four calm cards in a balanced grid for product fit, implementation challenge, privacy boundary, long-term trust, each card split into risk side and response side, warm neutral palette, stable and reassuring visual language, clear labels and separators, no alarmist style
```

## 使用建议

- 如果用于正文插图，优先保持统一画风、统一配色、统一卡片样式和统一留白比例。
- 如果需要“图里有字”，更建议生成带标题栏、注释栏、说明框的结构图，再在 LaTeX 或 PPT 中人工覆盖中文文字。
- 如果用于答辩 PPT，可在此基础上适度增强信息层级，但不要转向强科技感或强商业海报风。
- 如果后续改用真实系统截图，可保留这些 prompt 用于封面图、章节页和信息示意图。
- 若需要批量生成，建议所有 prompt 都保留统一风格模板，并只替换场景主体与结构关系，避免整本计划书插画风格飘散。
