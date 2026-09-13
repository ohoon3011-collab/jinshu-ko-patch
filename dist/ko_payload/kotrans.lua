-- kotrans.lua  — Korean localization display layer (PLAINTEXT, freely editable)
-- Intercepts on-screen text at draw time and substitutes Chinese -> Korean.
-- Table keys / game logic are never touched: only the string handed to lib.DrawStr
-- is translated. Longest Chinese phrase is matched first; unknown text passes through.
-- Edit the `dict` table freely; no re-encryption needed. jymain calls KOTR(str).

local dict = {
  -- ===== 캐릭터 생성 / 공용 안내 =====
  ["主角名字"]="주인공 이름", ["按任意键继续"]="아무 키나 눌러 계속",

  -- ===== HUD / 시간 =====
  ["时光流逝"]="세월이 흐른다",
  ["天书"]="천서", ["天关"]="천관", ["层"]="층",
  ["年"]="년", ["月"]="월", ["日"]="일", ["时"]="시", ["夜幕"]="야막",

  -- ===== 문파명 =====
  ["江湖"]="강호", ["少林"]="소림", ["武当"]="무당", ["逍遥"]="소요",
  ["日月"]="일월", ["明教"]="명교", ["天机"]="천기", ["全真"]="전진",
  ["丐帮"]="개방", ["华山"]="화산", ["嵩山"]="숭산", ["青城"]="청성",
  ["衡山"]="형산", ["恒山"]="항산", ["泰山"]="태산", ["五毒"]="오독",
  ["古墓"]="고묘", ["血刀"]="혈도", ["灵霄"]="영소", ["峨眉"]="아미",
  ["崆峒"]="공동", ["昆仑"]="곤륜", ["桃花"]="도화", ["白驼"]="백타",
  ["六扇门"]="육선문", ["八卦"]="팔괘", ["慕容"]="모용", ["天龙寺"]="천룡사",
  ["星宿"]="성수", ["密宗"]="밀종", ["藏剑"]="장검", ["派"]="파",
  ["少林寺"]="소림사", ["寺"]="사",

  -- ===== 날씨 / 계절 / 시간대 =====
  ["上午"]="오전", ["下午"]="오후", ["中午"]="정오", ["早上"]="아침",
  ["晚上"]="저녁", ["凌晨"]="새벽", ["傍晚"]="해질녘", ["深夜"]="심야",
  ["晴朗"]="맑음", ["晴天"]="맑음", ["多云"]="구름많음", ["阴天"]="흐림",
  ["小雨"]="가랑비", ["大雨"]="큰비", ["下雨"]="비", ["下雪"]="눈",
  ["大雾"]="짙은 안개", ["刮风"]="바람", ["雷雨"]="뇌우",
  ["春"]="봄", ["夏"]="여름", ["秋"]="가을", ["冬"]="겨울",
  ["阴"]="음", ["阳"]="양",

  -- ===== 필드 UI / 마퀴 =====
  ["任务"]="임무", ["传闻"]="소문", ["江湖传闻"]="강호 소문",
  ["信息"]="정보", ["地图"]="지도", ["团队"]="팀", ["任命"]="임명",
  ["商店"]="상점", ["西域商人"]="서역 상인",
  ["欢迎来到金书群侠传！祝您游戏愉快。"]="금서군협전에 오신 것을 환영합니다! 즐거운 게임 되세요.",
  ["金书群侠传"]="금서군협전", ["小虾米"]="소하미",

  -- ===== 능력치 / 상태 (키이면서 표시) =====
  ["生命最大值"]="최대 생명", ["内力最大值"]="최대 내력",
  ["生命"]="생명", ["内力"]="내력", ["内力性质"]="내력 성질",
  ["攻击力"]="공격력", ["防御力"]="방어력", ["轻功"]="경공",
  ["拳掌功夫"]="권장술", ["指法技巧"]="지법", ["御剑能力"]="어검술",
  ["耍刀技巧"]="도법", ["特殊兵器"]="특수 병기",
  ["用毒能力"]="용독술", ["解毒能力"]="해독술", ["医疗能力"]="의료술",
  ["攻击带毒"]="독 공격", ["体质"]="체질", ["资质"]="자질",
  ["加用毒能力"]="용독술 증가", ["加医疗能力"]="의료술 증가",
  ["加解毒能力"]="해독술 증가", ["加攻击带毒"]="독 공격 증가", ["加暗器技巧"]="암기술 증가",
  ["声望"]="명성", ["经验"]="경험", ["修炼经验："]="수련 경험: ", ["修炼经验:"]="수련 경험: ", ["修炼经验"]="수련 경험", ["等级"]="레벨", ["尊号"]="존호",
  ["实    战"]="실전",
  ["门派"]="문파", ["武功"]="무공", ["装备"]="장비", ["状态"]="상태",
  ["物品"]="아이템", ["秘籍"]="비급", ["天赋"]="천부", ["经脉"]="경맥",

  -- ===== 아이템 분류 / 상점 =====
  ["剧情物品"]="스토리 아이템", ["神兵宝甲"]="신병보갑", ["武功秘籍"]="무공 비급",
  ["灵丹妙药"]="영단묘약", ["伤人暗器"]="암기",
  ["物品名称"]="아이템 이름", ["神秘物品"]="신비한 물품", ["物品说明"]="아이템 설명",
  ["无可用武功"]="사용 가능한 무공 없음", ["未找到有效武功数据"]="유효한 무공 데이터 없음",

  -- ===== 버튼 / 공용 UI =====
  ["确认"]="확인", ["确定"]="확인", ["取消"]="취소", ["最大"]="최대",
  ["清空"]="비우기", ["删除"]="삭제", ["返回"]="돌아가기",
  ["保存进度"]="진행 저장", ["读取进度"]="진행 불러오기", ["离开游戏"]="게임 나가기",
  ["保存"]="저장", ["读取"]="불러오기", ["暂未开放"]="아직 미개방",
  ["系统"]="시스템",

  -- ===== 메뉴 / 공통 UI (배치 1) =====
  ["姓名"]="이름", ["名称"]="명칭", ["请选择"]="선택하세요", ["请稍候......"]="잠시만 기다려 주세요......",
  ["请选择需要的操作"]="원하는 작업을 선택하세요",
  ["修炼"]="수련", ["查看"]="보기", ["选择"]="선택", ["数量"]="수량", ["使用数量"]="사용 수량",
  ["位置"]="위치", ["主角"]="주인공", ["存档名"]="저장 이름", ["品德"]="품덕",
  ["拳法"]="권법", ["指法"]="지법", ["剑法"]="검법", ["刀法"]="도법", ["奇门"]="기문",
  ["内功"]="내공", ["外功"]="외공", ["外 功"]="외공", ["内 轻"]="내공·경공", ["绝 学"]="절학",
  ["学武功"]="무공 배우기", ["绝学资格挑战"]="절학 자격 도전", ["闲  聊 "]="잡담 ",
  ["筛选关键字（空=显示全部）"]="필터 키워드(공백=전체 표시)", ["筛选："]="필터: ", ["筛选"]="필터",
  ["未找到匹配："]="일치 항목 없음: ", ["未找到匹配"]="일치 항목 없음",
  ["F1搜索"]="F1 검색", ["输入搜索关键字"]="검색어 입력",
  ["输入物品名关键字（空=全部）"]="아이템명 키워드(공백=전체)",
  ["购 物 车"]="장바구니", ["总 价："]="총 가격: ", ["总价"]="총 가격",
  ["存 款："]="예치금: ", ["存款"]="예치금", ["单价："]="단가: ", ["单价"]="단가",
  ["效果："]="효과: ", ["效果： "]="효과: ", ["效果:"]="효과:", ["效果"]="효과",
  ["页数："]="페이지 수: ", ["页 数："]="페이지 수: ", ["页数"]="페이지 수", ["页"]="페이지",
  ["（尚未选购商品）"]="(아직 선택한 상품 없음)",
  ["礼 品 商 店"]="선물 상점", ["周 目 商 店"]="회차 상점", ["商     店"]="상점",
  ["本天书解锁"]="본 천서 해금", ["(碎片)"]="(조각)", ["周目碎片"]="회차 조각", ["获得"]="획득",
  ["你要卖出什么物品？"]="무엇을 파시겠습니까?", ["此项暂不可选择"]="이 항목은 선택 불가",
  ["人物属性"]="인물 속성", ["游戏属性"]="게임 속성", ["内属："]="내공 속성: ", ["内属:"]="내공 속성: ", ["内属"]="내공 속성", ["境界："]="경지: ",
  ["模式"]="모드", ["下一步"]="다음", ["方向键移动 空格/回车选中 "]="방향키 이동  스페이스/엔터 선택 ",
  ["成长: "]="성장: ", ["好感增加"]="호감도 증가", ["生命增加"]="생명 증가", ["体质增长"]="체질 증가",
  ["攻击 "]="공격 ", ["防御 "]="방어 ", ["轻功 "]="경공 ",
  ["天赋点数"]="천부 포인트", ["天罡"]="천강", ["杂类"]="기타",
  ["体力不足，无法运功"]="체력이 부족하여 운공할 수 없습니다", ["内力不足，无法运功"]="내력이 부족하여 운공할 수 없습니다",
  ["此人不适合配备此物品"]="이 인물은 이 아이템을 장착할 수 없습니다",
  ["此人不适合修炼此物品"]="이 인물은 이 아이템을 수련할 수 없습니다",
  ["行囊整理完毕"]="소지품 정리 완료", ["一键换装"]="원클릭 착용", ["的造型"]="의 모습",
  ["按F1返回物品菜单"]="F1로 아이템 메뉴로", ["按F1查看详细说明"]="F1로 상세 설명 보기",
  ["★按ESC退出"]="★ESC로 나가기", ["按ESC键退出"]="ESC로 나가기", ["按ESC退出"]="ESC로 나가기",
  ["按ESC取消"]="ESC로 취소", ["回车键确认 ESC返回上层"]="엔터 확인  ESC 상위로",
  ["请问有需要我帮忙的地方吗？"]="도와드릴 일이 있으신가요?", ["转换成功!"]="전환 성공!",
  ["该类型没有武功"]="해당 유형의 무공 없음", ["该人物没有武功可替换"]="교체할 무공이 없습니다",
  ["是否要激活经脉"]="경맥을 활성화하시겠습니까", ["江湖中的神秘武学"]="강호의 신비한 무학",
  ["剧情任务"]="스토리 임무", ["你对哪种类型的武功感兴趣？"]="어떤 유형의 무공에 관심이 있습니까?",
  ["请选择喜欢的天赋内功类型"]="선호하는 천부 내공 유형을 선택하세요",
  ["请选择喜欢的天赋轻功类型"]="선호하는 천부 경공 유형을 선택하세요",
  ["请选择喜欢的天赋外功类型"]="선호하는 천부 외공 유형을 선택하세요",
  ["天赋外功不可重复。"]="천부 외공은 중복할 수 없습니다.", ["洗第几个天赋外功？"]="몇 번째 천부 외공을 초기화할까요?",
  ["天外1"]="천외1", ["天外2"]="천외2", ["你想要转换的内力性质"]="전환할 내력 성질",
  ["你意欲何为？ "]="무엇을 하시겠습니까? ", ["挑战高手"]="고수에게 도전", ["暂不挑战"]="도전 안 함",
  ["门派特性"]="문파 특성", ["代表武学"]="대표 무학", ["弟子?"]="제자?", ["弟子"]="제자",
  ["需要把内力改变成？"]="내력을 무엇으로 바꿀까요?", ["内力性质呢？"]="내력 성질은?",
  ["阴内"]="음의 내공", ["阳内"]="양의 내공", ["阴性"]="음성", ["阳性"]="양성",
  ["主运内功"]="주 운기 내공", ["主运轻功"]="주 운기 경공", ["可副运"]="부 운기 가능", ["优先使用"]="우선 사용",
  ["要查阅谁的状态"]="누구의 상태를 볼까요", ["要求谁离队"]="누구를 이탈시킬까요",
  ["需要调整谁的位置"]="누구의 위치를 조정할까요", ["谁要使用医术"]="누가 의술을 쓸까요",
  ["要医治谁"]="누구를 치료할까요", ["谁要帮人解毒"]="누가 해독을 도울까요", ["替谁解毒"]="누구를 해독할까요",
  ["中毒程度"]="중독 정도", ["抱歉！没有你游戏进行不下去"]="죄송합니다! 당신 없이는 게임을 진행할 수 없습니다",
  ["自动战斗中..."]="자동 전투 중...", ["按键 ESC 取消"]="ESC 키로 취소",
  ["是否与之过招(Y/N)?"]="겨루시겠습니까(Y/N)?", ["是否要求加入(Y/N)?"]="합류를 요청할까요(Y/N)?",
  ["是否(Y/N)?"]="하시겠습니까(Y/N)?",
  ["威力强化:"]="위력 강화: ", ["需求:"]="요구:", ["练出："]="연성: ", ["类型："]="유형: ",
  ["类    型："]="유형: ", ["已选："]="선택됨: ", ["已选择："]="선택됨: ", ["特长已选择："]="선택된 특기: ",
  ["已完成"]="완료", ["总成就"]="전체 업적", ["暂无"]="없음", ["近期通关记录"]="최근 클리어 기록",
  ["尚无武道大会记录"]="아직 무도대회 기록 없음", ["游历次数"]="유력 횟수",
  ["通关次数："]="클리어 횟수: ", ["通关时间 "]="클리어 시간 ", ["最高通关难度："]="최고 클리어 난이도: ", ["次"]="회",
  ["孩子信息"]="자녀 정보", ["请选择孩子的特长"]="자녀의 특기를 선택하세요", ["补丁补偿已发放"]="패치 보상이 지급되었습니다",
  ["请输入资质"]="자질을 입력하세요", ["请输入数值"]="숫자를 입력하세요", ["请输入密码:"]="비밀번호 입력:",
  ["输入密码"]="비밀번호 입력", ["错误,密码错误！"]="오류, 비밀번호가 틀렸습니다!",
  ["选择性别"]="성별 선택", ["游戏设置"]="게임 설정", ["远景"]="원경", ["中景"]="중경", ["近景"]="근경",
  ["当前已是该设置，无需修改"]="이미 해당 설정입니다", ["请重新启动游戏生效"]="게임을 재시작해야 적용됩니다",
  ["三日后"]="3일 후", ["在地球的某处"]="지구 어딘가에서", ["又多了一笔。。。"]="또 하나 늘었다...",

  -- ===== NPC 머리 위 말풍선 (talktable) =====
  ["旁边的丹炉可以炼药，灶炉可以做菜和酒。"]="옆의 단로에서 약을 만들고, 부뚜막에서 요리와 술을 만들 수 있다.",
  ["，我这里出售药材食材，也收购一些物品。"]="， 이곳에서 약재와 식재료를 팔고 물품도 사들인다.",
  ["，我可以为你行走江湖提供一些便利。"]="， 그대가 강호를 다니는 데 편의를 제공하겠다.",
  ["武功的皮毛,有人要与我互相切磋吗？"]=" 무공의 겉핥기일 뿐, 나와 겨뤄볼 자 있는가?",
  ["，我有跟神秘小姐姐不一样的能力。"]="， 나는 신비한 아가씨와는 다른 능력이 있다.",
  ["弟子可以从我这里学习武功。"]="제자는 나에게서 무공을 배울 수 있다.",
  ["，我这里出售一些物品。"]="， 이곳에서 물품을 판다.",
  ["爹爹和娘亲快来和我玩。"]="아버지 어머니, 어서 와서 저랑 놀아요.",
  ["，客官要住店吗？"]="， 손님, 묵고 가시겠습니까?",
  ["，客官有何吩咐？"]="， 손님, 무엇을 도와드릴까요?",
  ["我还只学到我们"]="나는 아직 우리 ",
  ["我是本店的"]="나는 이 가게의 ", ["我是"]="나는 ", ["孩子"]="아이",

  -- ===== 인물 이름 (초반/주요) =====
  ["散人"]="산인", ["江湖散人"]="강호 산인", ["苗人凤"]="묘인봉",
  ["令狐冲"]="영호충", ["胡斐"]="호비",
}

-- ===== 대사 통문장 (정확 매칭; say 후크에서 reflow 전에 번역) =====
-- key = TalkEx/say 에 넘어가는 원문 그대로(제어코드 * 포함). 성능을 위해 부분치환 루프에 안 들어감.
local lines = {
  ["小兄弟，行走江湖记得多行*侠仗义。"]="젊은 친구, 강호를 다닐 땐 부디 협의를 많이 행하시게.",
  ["小姑娘，行走江湖记得多行*侠仗义。"]="젊은 낭자, 강호를 다닐 땐 부디 협의를 많이 행하시게.",
}

local talkArchive = {}
local dynamicTemplates = {}
do
  local ok, extra = pcall(require, "kotrans_lines")
  if ok and type(extra) == "table" then for k, v in pairs(extra) do lines[k] = v end end
  local ok2, extra2 = pcall(require, "kotrans_terms")
  if ok2 and type(extra2) == "table" then for k, v in pairs(extra2) do dict[k] = v end end
  local ok3, extra3 = pcall(require, "kotrans_talk")
  if ok3 and type(extra3) == "table" then talkArchive = extra3 end
  local ok4, extra4 = pcall(require, "kotrans_talk_lines")
  if ok4 and type(extra4) == "table" then
    for k, v in pairs(extra4) do
      lines[k] = v
      lines[(k:gsub("%*", ""))] = v
    end
  end
  local ok5, extra5 = pcall(require, "kotrans_dynamic")
  if ok5 and type(extra5) == "table" then dynamicTemplates = extra5 end
  -- FIX144 통합패치에서 검수된 추가 번역을 안전하게 흡수한다.
  -- 표시용 사전만 합치므로 구버전 핵심 스크립트로 되돌아가지 않는다.
  local ok6, extra6 = pcall(require, "kotrans_fix144")
  if ok6 and type(extra6) == "table" then for k, v in pairs(extra6) do dict[k] = v end end
  -- 최신 FIX에서 새로 추가된 천부·무공 문구. 뒤에서 합쳐 최신 표현이 우선한다.
  local ok7, extra7 = pcall(require, "kotrans_fix146")
  if ok7 and type(extra7) == "table" then for k, v in pairs(extra7) do dict[k] = v end end
  local ok8, extra8 = pcall(require, "kotrans_fix147")
  if ok8 and type(extra8) == "table" then for k, v in pairs(extra8) do dict[k] = v end end
  local ok9, extra9 = pcall(require, "kotrans_changelog_128_143")
  if ok9 and type(extra9) == "table" then for k, v in pairs(extra9) do dict[k] = v end end
  -- 경맥 화면 전용: 경혈명과 번체 설명을 통문장 단위로 처리한다.
  local ok10, extra10 = pcall(require, "kotrans_meridians")
  if ok10 and type(extra10) == "table" then for k, v in pairs(extra10) do dict[k] = v end end
  -- FIX148-150 reviewed release notes and talent additions.
  local ok11, extra11 = pcall(require, "kotrans_fix150")
  if ok11 and type(extra11) == "table" then for k, v in pairs(extra11) do dict[k] = v end end
end

if type(ReadTalk) == "function" then
  local originalReadTalk = ReadTalk
  ReadTalk = function(id, flag)
    if flag == nil and type(id) == "number" then
      local translated = talkArchive[id]
      if translated ~= nil then return translated end
    end
    return originalReadTalk(id, flag)
  end
end

local patch = require("kotrans_patch")
for source, target in pairs(patch.lines) do lines[source] = target end
for source, target in pairs(patch.terms) do dict[source] = target end
for index = #patch.dynamic, 1, -1 do table.insert(dynamicTemplates, 1, patch.dynamic[index]) end

-- build order: longest Chinese key first (so phrases win over single chars)
local order = {}
for k in pairs(dict) do order[#order+1] = k end
table.sort(order, function(a, b)
  if #a ~= #b then return #a > #b end
  return a < b
end)

local memo = {}
local ensure_runtime_hooks, ensure_tjm_hook, ensure_draw3_hook
local localize_format = require("kotrans_formats").build(dict, lines)

-- plain (non-pattern) substring replace so keys/values with % + . etc. are safe
local sfind, ssub, tconcat = string.find, string.sub, table.concat
local function greplace(s, from, to)
  local pos = sfind(s, from, 1, true)
  if not pos then return s end
  local out, init = {}, 1
  while pos do
    out[#out+1] = ssub(s, init, pos - 1)
    out[#out+1] = to
    init = pos + #from
    pos = sfind(s, from, init, true)
  end
  out[#out+1] = ssub(s, init)
  return tconcat(out)
end

local function match_dynamic_template(s, template)
  local parts = template.parts
  if type(parts) ~= "table" or #parts == 0 then return nil end
  local firstStart, firstEnd = sfind(s, parts[1], 1, true)
  while firstStart do
    if not template.head or firstStart == 1 then
      local captures = {}
      if not template.head then captures[#captures + 1] = ssub(s, 1, firstStart - 1) end
      local pos, matched = firstEnd + 1, true
      for i = 2, #parts do
        local partStart, partEnd = sfind(s, parts[i], pos, true)
        if not partStart then
          matched = false
          break
        end
        captures[#captures + 1] = ssub(s, pos, partStart - 1)
        pos = partEnd + 1
      end
      if matched and (not template.tail or pos == #s + 1) then
        if not template.tail then captures[#captures + 1] = ssub(s, pos) end
        return captures
      end
    end
    if template.head then break end
    firstStart, firstEnd = sfind(s, parts[1], firstStart + 1, true)
  end
end

local numeralDigits = {
  ["零"]=0, ["一"]=1, ["二"]=2, ["三"]=3, ["四"]=4,
  ["五"]=5, ["六"]=6, ["七"]=7, ["八"]=8, ["九"]=9, ["Ο"]=0,
  ["0"]=0, ["1"]=1, ["2"]=2, ["3"]=3, ["4"]=4,
  ["5"]=5, ["6"]=6, ["7"]=7, ["8"]=8, ["9"]=9,
}
local numeralUnits = {["十"]=10, ["百"]=100, ["千"]=1000}
local function display_number(value)
  local negative = false
  local head = ssub(value, 1, 3)
  if head == "陰" or head == "阴" or head == "負" or head == "负" then
    negative, value = true, ssub(value, 4)
  elseif ssub(value, 1, 1) == "-" then
    negative, value = true, ssub(value, 2)
  end
  local function signed(number)
    return (negative and "-" or "") .. tostring(number)
  end
  if value:match("^%d+$") then return signed(value) end
  local characters, hasUnit = {}, false
  for character in value:gmatch("[\1-\127\194-\244][\128-\191]*") do
    if numeralDigits[character] == nil and numeralUnits[character] == nil then return nil end
    characters[#characters + 1] = character
    hasUnit = hasUnit or numeralUnits[character] ~= nil
  end
  if #characters == 0 then return nil end
  if not hasUnit then
    local digits = {}
    for _, character in ipairs(characters) do digits[#digits + 1] = tostring(numeralDigits[character]) end
    return signed(table.concat(digits))
  end
  local total, pending, previousUnit = 0, nil, 10000
  for _, character in ipairs(characters) do
    local unit = numeralUnits[character]
    if unit then
      if unit >= previousUnit then return nil end
      total = total + (pending or 1) * unit
      pending, previousUnit = nil, unit
    else
      if pending and pending ~= 0 then return nil end
      pending = numeralDigits[character]
    end
  end
  return signed(total + (pending or 0))
end

local numericFormatCaptures = {
  ["【%s】第Ｇ%sＷ招：%s"] = 2,
  ["【%s】第Ｇ%sＷ招：%s  Ｚ%sＷ"] = 2,
  ["Ｚ【%s】Ｗ第Ｚ%sＷ招：%s"] = 2,
  ["Ｇ%sＨ第Ｄ%sＨ招:Ｄ%s"] = 2,
  ["第%s组  %s·%s  VS  %s·%s"] = 1,
  ["%s 升为第%s级"] = 2,
}
local function translate_format_capture(value, source, index)
  if numericFormatCaptures[source] == index then
    local number = display_number(value)
    if number then return number end
  end
  return KOTR(value)
end

local function localize_dynamic(s)
  if s == "Ｇ【一脉相承】" then return "Ｇ【무공 계승】" end
  if s == "【一脉相承】" then return "【무공 계승】" end
  local inheritance = s:match("^Ｇ【一脉相承】%*Ｗ(.+)$")
  if inheritance then return "Ｇ【무공 계승】*Ｗ" .. KOTR(inheritance) end

  local page, pages = s:match("^第%s*(%d+)%s*/%s*(%d+)%s*页%s*$")
  if page then return page .. " / " .. pages .. " 페이지" end

  local cost = s:match("^需天赋点：%s*Ｚ(.+)$")
  if cost then
    local number = display_number(cost)
    if number then return "필요 천부 포인트: Ｚ" .. number end
  end

  local winner, rank = s:match("^→ (.-)·(.-) 胜$")
  if winner and winner ~= "" and rank ~= "" then
    return "→ " .. KOTR(winner) .. "·" .. KOTR(rank) .. " 승리"
  end

  local sectName, personName, sceneName = s:match("^Ｗ传闻Ｏ(.-)Ｗ的Ｏ(.-)Ｗ出现在Ｏ(.-)$")
  if sectName then
    return "Ｗ소문: Ｏ" .. KOTR(sectName) .. "Ｗ 소속 Ｏ" .. KOTR(personName) .. "Ｗ, Ｏ" .. KOTR(sceneName) .. "Ｗ에 나타났다."
  end

  local feedbackNotice = s:gsub("%s+", "")
  if feedbackNotice == "更新下载问题反馈请加QQ群号：198045761" or
     feedbackNotice == "更新下载问题反馈请加QQ群号:198045761" then
    return "업데이트·다운로드 관련 문의는 QQ 그룹 198045761로 연락해 주세요."
  end

  local tipSpeaker = s:match("^(.-)，主运内功能给同门派的外功加成威力，获得更高的门派贡献也能增加门派武功的威力。$")
  if tipSpeaker then
    return KOTR(tipSpeaker) .. ", 주력 내공은 같은 문파의Ｈ외공을 강화한다네. 문파 공헌도가Ｈ높을수록 문파 무공도 강해지지."
  end

  local eventPrefix, eventTalent = s:match("^(.-)观武切磋，领悟了天赋(.-)，名动江湖$")
  if eventPrefix and eventTalent then
    return KOTR(eventPrefix) .. "여러 무예를 익히고 겨룬 끝에 천부를 깨우쳤다: " ..
      KOTR(eventTalent) .. ". 강호에 이름을 떨쳤다."
  end

  local speaker, body = s:match("^(.-)，(.+)$")
  local exactBody = body and (lines[body] or lines[(body:gsub("%*", ""))])
  if speaker and exactBody then
    return KOTR(speaker) .. ", " .. exactBody
  end

  local baseDamage, innerDamage, extraDamage = s:match(
    "^造成基础伤害Ｇ(.-)Ｈ点。造成目标内伤Ｇ(.-)Ｈ点。附加额外伤害Ｇ(.-)Ｈ点。$")
  if baseDamage then
    return "기본 피해를 Ｇ" .. KOTR(baseDamage) .. "Ｈ만큼 입히고, 대상의 내상을 Ｇ" ..
      KOTR(innerDamage) .. "Ｈ만큼 높입니다. 추가로 고정 피해를 Ｇ" ..
      KOTR(extraDamage) .. "Ｈ만큼 입힙니다."
  end

  local inheritedFrom, inheritedTo = s:match("^(.-)一脉相承(.-)$")
  if inheritedFrom and inheritedFrom ~= "" and inheritedTo ~= "" and
     #inheritedFrom <= 60 and #inheritedTo <= 60 and
     not sfind(s, "。", 1, true) and not sfind(s, "，", 1, true) and
     not sfind(s, "*", 1, true) and not sfind(s, "【", 1, true) and
     not sfind(s, "】", 1, true) then
    return KOTR(inheritedFrom) .. "에서 " .. KOTR(inheritedTo) ..
      "으로 숙련도를 이어받습니다."
  end

  for i = 1, #dynamicTemplates do
    local template = dynamicTemplates[i]
    local captures = match_dynamic_template(s, template)
    if captures then
      return (template.value:gsub("{{(%d+)}}", function(index)
        return KOTR(captures[tonumber(index)] or "")
      end))
    end
  end
end

local function localize_npc_bubble(s)
  local joined, sect = s:match("^我是Ｒ(.-)Ｗ,Ｒ(.-)Ｗ弟子可以从我这里学习武功。$")
  if joined and sect and ssub(joined, 1, #sect) == sect then
    local name = ssub(joined, #sect + 1)
    return "나는 Ｒ" .. KOTR(sect) .. "의 " .. KOTR(name) .. "Ｗ일세. Ｒ" .. KOTR(sect) .. "Ｗ 제자라면 내게서 무공을 배울 수 있네."
  end

  local name = s:match("^我是Ｒ(.-)Ｗ，我有跟神秘小姐姐不一样的能力。$")
  if name then return "저는 Ｒ" .. KOTR(name) .. "Ｗ이에요. 신비한 소녀와는 다른 능력을 지니고 있어요." end

  name = s:match("^我是Ｒ(.-)Ｗ，我可以为你行走江湖提供一些便利。$")
  if name then return "저는 Ｒ" .. KOTR(name) .. "Ｗ이에요. 강호를 돌아다니는 데 여러모로 도와드릴 수 있어요." end

  name = s:match("^我是Ｒ(.-)Ｗ，我这里出售药材食材，也收购一些物品。$")
  if name then return "나는 Ｒ" .. KOTR(name) .. "Ｗ이오. 약재와 식재료를 팔고, 물건도 사들이고 있소." end

  name = s:match("^我是本店的Ｒ(.-)Ｗ，客官有何吩咐？$")
  if name then return "저는 이 객잔의 점소이 Ｒ" .. KOTR(name) .. "Ｗ입니다. 무엇을 도와드릴까요?" end

  name = s:match("^我是本店的Ｒ(.-)Ｗ，客官要住店吗？$")
  if name then return "저는 이 객잔의 주인 Ｒ" .. KOTR(name) .. "Ｗ입니다. 묵고 가시겠습니까?" end

  name = s:match("^我是Ｒ(.-)Ｗ，我这里出售一些物品。$")
  if name then return "나는 상인 Ｒ" .. KOTR(name) .. "Ｗ이오. 여기서 여러 물건을 팔고 있소." end

  sect = s:match("^我还只学到我们Ｒ(.-)Ｗ武功的皮毛,有人要与我互相切磋吗？$")
  if sect then return "나는 아직 우리 Ｒ" .. KOTR(sect) .. "Ｗ 무공의 기초만 익혔소. 나와 비무해 볼 사람 있소?" end

  local student
  student, sect = s:match("^(.-)，修炼武学，需勤加练习，(.-)派功夫讲究循序渐进，你找我有何事？$")
  if not student then
    student, sect = s:match("^(.-)，修炼武学，需勤加练习，(.-)功夫讲究循序渐进，你找我有何事？$")
  end
  if student and sect then
    return KOTR(student) .. ", 무학은 부지런히 수련해야 하느니라. " .. KOTR(sect) .. "파의 무공은 차근차근 경지를 쌓는 것을 중시한다. 무슨 일로 나를 찾았느냐?"
  end
end

local zeroWidthControl = {
  ["Ｐ"]=true, ["Ｒ"]=true, ["Ｇ"]=true, ["Ｂ"]=true, ["Ｗ"]=true,
  ["Ｏ"]=true, ["Ｌ"]=true, ["Ｄ"]=true, ["Ｚ"]=true, ["Ｈ"]=true,
  ["Ｓ"]=true, ["Ｆ"]=true,
}

local displayColors = {['Ｒ']=true, ['Ｇ']=true, ['Ｂ']=true, ['Ｗ']=true, ['Ｏ']=true, ['Ｌ']=true, ['Ｄ']=true, ['Ｚ']=true, ['Ｈ']=true}
local colorlessLines = {}
for source, target in pairs(lines) do
  if displayColors[source:sub(1, 3)] and #source > 3 then
    local body = source:sub(4)
    local translated = displayColors[target:sub(1, 3)] and target:sub(4) or target
    if colorlessLines[body] == nil then
      colorlessLines[body] = translated
    elseif colorlessLines[body] ~= translated then
      colorlessLines[body] = false
    end
  end
end

local function exact_line(s)
  local exact = lines[s]
  if exact == nil then exact = colorlessLines[s] or nil end
  if exact == nil and sfind(s, "*", 1, true) then
    exact = lines[(s:gsub("%*", ""))]
  end
  return exact
end

local function split_control_prefix(s)
  local index = 1
  while index + 2 <= #s do
    local control = s:sub(index, index + 2)
    if not zeroWidthControl[control] then break end
    index = index + 3
  end
  if index == 1 then return nil, nil end
  return s:sub(1, index - 1), s:sub(index)
end

-- Some legacy DB rows use Traditional Chinese while the reviewed dictionary
-- keys use Simplified Chinese. Normalize common variants before lookup so the
-- same full-sentence translation covers both forms.
local traditionalToSimplified = {
  ["體"]="体", ["敵"]="敌", ["內"]="内", ["並"]="并", ["亂"]="乱",
  ["時"]="时", ["發"]="发", ["動"]="动", ["傷"]="伤", ["擊"]="击",
  ["進"]="进", ["戰"]="战", ["個"]="个", ["劍"]="剑", ["極"]="极",
  ["減"]="减", ["為"]="为", ["則"]="则", ["點"]="点", ["殺"]="杀",
  ["機"]="机", ["會"]="会", ["無"]="无", ["視"]="视", ["類"]="类",
  ["屬"]="属", ["與"]="与", ["氣"]="气", ["間"]="间", ["長"]="长",
  ["檔"]="档", ["遊"]="游", ["戲"]="戏", ["靈"]="灵", ["萬"]="万",
  ["蠱"]="蛊", ["雲"]="云", ["陽"]="阳", ["陰"]="阴", ["聖"]="圣",
  ["對"]="对", ["項"]="项", ["數"]="数", ["後"]="后", ["開"]="开",
  ["關"]="关", ["轉"]="转", ["換"]="换", ["絕"]="绝", ["學"]="学",
  ["經"]="经", ["脈"]="脉", ["輕"]="轻", ["傳"]="传", ["門"]="门",
  ["紊"]="紊", ["態"]="态", ["種"]="种", ["隨"]="随",
  ["統"]="统", ["計"]="计", ["員"]="员", ["衝"]="冲",
  ["裏"]="里", ["裡"]="里",
  ["獲"]="获", ["復"]="复", ["歸"]="归", ["隱"]="隐",
  ["觸"]="触", ["強"]="强", ["護"]="护", ["擋"]="挡", ["離"]="离",
}

local function normalize_traditional(s)
  local result = s
  for old, new in pairs(traditionalToSimplified) do
    if sfind(result, old, 1, true) then result = greplace(result, old, new) end
  end
  return result
end

function KOTR(s)
  if ensure_runtime_hooks then ensure_runtime_hooks() end
  if type(s) ~= "string" then return s end
  local c = memo[s]
  if c ~= nil then return c end
  -- exact whole-line match first (dialogue) — O(1), covers the huge `lines` table.
  -- '*' is a no-op line-break marker in say(); strip it so one key matches every
  -- wrap-variant of the same line (its position shifts with the speaker-name prefix).
  local exact = exact_line(s)
  if exact ~= nil then
    memo[s] = exact
    return exact
  end
  local prefix, body = split_control_prefix(s)
  local bodyExact = body and exact_line(body)
  if bodyExact ~= nil then
    local translated = prefix .. bodyExact
    memo[s] = translated
    return translated
  end
  local direct = dict[s]
  if direct ~= nil then
    memo[s] = direct
    return direct
  end
  -- Try reviewed Traditional-Chinese sentences before normalizing them.  The
  -- FIX144/146 database contains deliberate Traditional variants whose exact
  -- translations are better than a later collection of partial replacements.
  local normalized = normalize_traditional(s)
  if normalized ~= s then
    local translated = KOTR(normalized)
    memo[s] = translated
    return translated
  end
  local formatted = localize_format(s, translate_format_capture)
  if not formatted and body then
    local bodyFormatted = localize_format(body, translate_format_capture)
    if bodyFormatted then formatted = prefix .. bodyFormatted end
  end
  if formatted then
    memo[s] = formatted
    return formatted
  end
  local bubble = localize_npc_bubble(s)
  if bubble ~= nil then
    memo[s] = bubble
    return bubble
  end
  local dynamic = localize_dynamic(s)
  if dynamic ~= nil then
    memo[s] = dynamic
    return dynamic
  end
  -- fast path: skip if no CJK-ideograph lead byte (UTF-8 0xE4..0xE9)
  if not sfind(s, "[\228\229\230\231\232\233]") then
    memo[s] = s
    return s
  end
  -- substring replacement over UI/name phrases (P), longest-first
  local r = s
  for i = 1, #order do
    local k = order[i]
    if sfind(r, k, 1, true) then r = greplace(r, k, dict[k]) end
  end
  memo[s] = r
  return r
end

local drawStringHooked = false
local effectTextHooked = false
local function utf8chars(s)
  local out, i = {}, 1
  while i <= #s do
    local b = s:byte(i)
    local n = (b < 0x80) and 1 or (b < 0xE0) and 2 or (b < 0xF0) and 3 or 4
    out[#out + 1] = s:sub(i, i + n - 1)
    i = i + n
  end
  return out
end

local function translateDrawString(str)
  if type(str) ~= "string" or not sfind(str, "*", 1, true) then return KOTR(str) end
  local parts, vertical = {}, true
  for part in (str .. "*"):gmatch("([^*]*)%*") do
    parts[#parts + 1] = part
    if #utf8chars(part) ~= 1 then vertical = false end
  end
  if vertical and #parts >= 2 and #parts <= 4 then
    local compact = table.concat(parts)
    local translated = KOTR(compact):gsub("%*", "")
    if translated ~= compact then return table.concat(utf8chars(translated), "*") end
  end
  return (str:gsub("[^*]+", function(part) return KOTR(part) end))
end

ensure_runtime_hooks = function()
  if not drawStringHooked and type(DrawString) == "function" then
    local original = DrawString
    drawStringHooked = true
    DrawString = function(x, y, str, ...)
      return original(x, y, translateDrawString(str), ...)
    end
  end
  -- 전투 특수효과 이름은 Set_Eff_Text가 내부에서 글자 단위로 쪼갠 뒤
  -- 그리므로, 쪼개기 전의 통문장을 먼저 번역한다.
  if not effectTextHooked and type(Set_Eff_Text) == "function" then
    local originalSetEffText = Set_Eff_Text
    effectTextHooked = true
    Set_Eff_Text = function(id, slot, str, ...)
      return originalSetEffText(id, slot, KOTR(str), ...)
    end
  end
  if ensure_tjm_hook then ensure_tjm_hook() end
  if ensure_draw3_hook then ensure_draw3_hook() end
end

-- ===== 대화 박스 자동 줄바꿈(reflow) =====
-- 한글은 폭이 넓고 공백이 섞이면 say의 자동 줄바꿈(cx==24 정확 비교)이 건너뛰어
-- 텍스트가 박스 밖으로 넘친다. 그래서 번역문을 폭에 맞춰 미리 'Ｈ'(줄바꿈 제어코드)로
-- 재배치한다. 3줄이 차면 say가 자동으로 페이지 넘김+키 대기를 처리한다.
-- 색상(ＲＧＢＷＯＬＤＺ)/글꼴(ＳＦ)/이름(Ｎｎ)/대기(ｗｐ)/숫자(０-９)/페이지(Ｐ) 제어코드는 보존.
local LINE_BUDGET = 18   -- 한 줄 최대 폭 단위(한글 1, 영문/숫자 0.5). 넘침 시 낮출 것.

local CTRL = {  -- 폭 0, 그대로 통과
  [0xFF32]=1,[0xFF27]=1,[0xFF22]=1,[0xFF37]=1,[0xFF2F]=1,[0xFF2C]=1,[0xFF24]=1,[0xFF3A]=1, -- 색상 ＲＧＢＷＯＬＤＺ
  [0xFF33]=1,[0xFF26]=1, -- 글꼴 ＳＦ
  [0xFF57]=1,[0xFF50]=1, -- 대기 ｗｐ
}
for cp=0xFF10,0xFF19 do CTRL[cp]=1 end -- 숫자 ０-９(딜레이)

local function nextchar(s, i)
  local b = s:byte(i)
  if not b then return nil end
  local len = (b < 0x80) and 1 or (b < 0xE0) and 2 or (b < 0xF0) and 3 or 4
  local cp
  if len == 1 then cp = b
  elseif len == 2 then cp = (b-0xC0)*64 + (s:byte(i+1)-0x80)
  elseif len == 3 then cp = (b-0xE0)*4096 + (s:byte(i+1)-0x80)*64 + (s:byte(i+2)-0x80)
  else cp = (b-0xF0)*262144 + (s:byte(i+1)-0x80)*4096 + (s:byte(i+2)-0x80)*64 + (s:byte(i+3)-0x80) end
  return s:sub(i, i+len-1), cp, i+len
end

-- `tjm`은 원문을 글자 단위로 끊기 때문에 한글 조사와 숫자 단위가 다음 줄
-- 첫머리로 밀린다. 번역이 끝난 문자열을 공백 경계에서 먼저 접고, 한 단어가
-- 칸보다 긴 경우에만 기존과 같이 글자 경계에서 접는다. 색상 제어문자는 폭을
-- 차지하지 않으며 기존 `*`/`Ｎ` 줄바꿈은 그대로 보존한다.
local tjmControl = {
  ["Ｐ"]=true, ["Ｒ"]=true, ["Ｇ"]=true, ["Ｂ"]=true, ["Ｗ"]=true,
  ["Ｏ"]=true, ["Ｌ"]=true, ["Ｄ"]=true, ["Ｚ"]=true, ["Ｈ"]=true,
  ["Ｓ"]=true, ["Ｆ"]=true,
}

local function wrap_tjm_words(s, xnum)
  local limit = tonumber(xnum)
  if type(s) ~= "string" or not limit or limit <= 0 then return s end

  local out, width, afterSpace, lastSpace, i = {}, 0, 0, nil, 1
  while true do
    local ch, cp, ni = nextchar(s, i)
    if not ch then break end
    i = ni

    if ch == "*" or ch == "Ｎ" then
      out[#out + 1] = ch
      width, afterSpace, lastSpace = 0, 0, nil
    elseif tjmControl[ch] then
      out[#out + 1] = ch
    else
      local charWidth = (cp < 0x80) and 0.5 or 1
      if ch == " " then
        if width + charWidth > limit then
          out[#out + 1] = "*"
          width, afterSpace, lastSpace = 0, 0, nil
        else
          out[#out + 1] = ch
          width = width + charWidth
          lastSpace = #out
          afterSpace = 0
        end
      else
        if width + charWidth > limit then
          if lastSpace then
            out[lastSpace] = "*"
            width = afterSpace
            lastSpace = nil
          else
            out[#out + 1] = "*"
            width = 0
          end
        end
        out[#out + 1] = ch
        width = width + charWidth
        if lastSpace then afterSpace = afterSpace + charWidth end
      end
    end
  end
  return table.concat(out)
end

function KOTR_tjm(str, xnum)
  if type(str) ~= "string" then return str end

  local whole = exact_line(str)
  local prefix, body = split_control_prefix(str)
  local bodyWhole = body and exact_line(body)
  if whole ~= nil then
    str = whole
  elseif bodyWhole ~= nil then
    str = prefix .. bodyWhole
  elseif sfind(str, "*", 1, true) then
    str = str:gsub("[^*]+", function(seg)
      local lead, core, tail = seg:match("^(%s*)(.-)(%s*)$")
      local translated = KOTR(core):gsub("^%*+", ""):gsub("%*+$", "")
      return lead .. translated .. tail
    end)
  else
    str = KOTR(str)
  end

  return wrap_tjm_words(str, xnum)
end

local reflowMemo = {}
local function reflow(s)
  if type(s) ~= "string" or s == "" then return s end
  local c = reflowMemo[s]; if c ~= nil then return c end
  local out, w, i = {}, 0, 1
  while true do
    local ch, cp, ni = nextchar(s, i)
    if not ch then break end
    i = ni
    if cp == 0x2A then                 -- '*' : say에서 무의미 → 제거
    elseif cp == 0xFF28 or cp == 0xFF30 then  -- Ｈ 줄바꿈 / Ｐ 페이지 : 강제 개행
      out[#out+1] = ch; w = 0
    elseif cp == 0xFF2E or cp == 0xFF4E then  -- Ｎ/ｎ 이름 삽입 : 대략 2폭
      out[#out+1] = ch; w = w + 2
    elseif CTRL[cp] then               -- 기타 제어코드 : 폭 0 통과
      out[#out+1] = ch
    else
      local cw = (cp < 0x80) and 0.5 or 1
      if w + cw > LINE_BUDGET then
        out[#out+1] = "\239\188\168"   -- 'Ｈ' (U+FF28) 줄바꿈 삽입
        w = 0
      end
      out[#out+1] = ch; w = w + cw
    end
  end
  local r = table.concat(out)
  reflowMemo[s] = r
  return r
end
KOTR_reflow = reflow

-- Dialogue hook: translate the WHOLE line, then reflow to fit the box.
-- `say` is defined in jymenu (loaded before this module), so it exists now.
if type(say) == "function" then
  local _say = say
  say = function(s, ...) return _say(reflow(KOTR(s)), ...) end
end

-- Draw-function hooks: some renderers hand the draw primitive ONE glyph at a
-- time (tjm lays text out char-by-char for wrapping; the vertical/gradient/
-- outline drawers likewise), so the primitive-level translation only ever sees
-- single CJK chars and can't match a phrase. Translate the WHOLE string once at
-- entry here. KOTR is idempotent (already-Korean / no-CJK returns unchanged and
-- is memoized), so this composes safely with any lower-level translation.
-- All of these globals are defined before kotrans is required (jymain loads
-- jyconst/jymenu/custom first); the type guards make a missing one a no-op.
local tjmHooked = false
ensure_tjm_hook = function()
  if tjmHooked or type(tjm) ~= "function" then return end
  if rawget(_G, "KOTR_TJM_INLINE") then
    tjmHooked = true
    return
  end
  local originalTjm = tjm
  tjmHooked = true
  tjm = function(x, y, str, color, size, xnum, ...)
    str = KOTR_tjm(str, xnum)
    return originalTjm(x, y, str, color, size, xnum, ...)
  end
end
ensure_tjm_hook()

-- 경맥도 경혈명은 draw3가 통문장을 한 글자씩 자른 뒤 DrawString에 넘긴다.
-- 자르기 전에 번역해야 '極泉' 같은 이름 전체가 '극천'으로 바뀐다.
local draw3Hooked = false
ensure_draw3_hook = function()
  if draw3Hooked or type(draw3) ~= "function" then return end
  local originalDraw3 = draw3
  draw3Hooked = true
  draw3 = function(str, ...)
    return originalDraw3(KOTR(str), ...)
  end
end
ensure_draw3_hook()
-- DrawStringVertical/Grad/Outline live in custom.lua, which is required AFTER
-- this module in jymain's init — so at this point they may not exist yet. Force
-- custom to load now (require is cached, so jymain's later require is a no-op)
-- then wrap. Vertical labels (属性/武功/尊号… on the character panel and tabs)
-- go through DrawStringVertical, so without this they stay Chinese.
pcall(require, "custom")
if type(DrawStringVertical) == "function" then
  local _dsv = DrawStringVertical
  DrawStringVertical = function(x, y, str, ...) return _dsv(x, y, KOTR(str), ...) end
end
if type(DrawStringGrad) == "function" then
  local _dsg = DrawStringGrad
  DrawStringGrad = function(x, y, str, ...) return _dsg(x, y, KOTR(str), ...) end
end
if type(DrawStringOutline) == "function" then
  local _dso = DrawStringOutline
  DrawStringOutline = function(x, y, str, ...) return _dso(x, y, KOTR(str), ...) end
end

local function localize_character_ui(picid)
  if type(DrawString) ~= "function" then return end
  ensure_runtime_hooks()
  local bx, by = (CC and CC.WX) or 1, (CC and CC.HY) or 1
  local scale = math.min(bx, by)
  local black = C_BLACK or RGB(0, 0, 0)
  local dark = RGB(28, 28, 28)
  local white = C_WHITE or RGB(255, 255, 255)
  local gold = C_GOLD or RGB(255, 215, 0)
  local function fill(x1, y1, x2, y2, color)
    lib.Background(x1 * bx, y1 * by, x2 * bx, y2 * by, 0, color)
  end
  local function text(x, y, value, color, size, font, align)
    DrawString(x * bx, y * by, value, color, size * scale, font or CC.FONT2, align or "center", 1)
  end

  if picid == 18 then
    fill(618, 12, 744, 62, dark)
    text(681, 17, "물품", gold, 35)
    return
  elseif picid == 26 then
    fill(548, 5, 812, 67, black)
    text(680, 12, "업적 모음", white, 35)
    return
  elseif picid == 168 then
    fill(474, 198, 884, 302, RGB(18, 18, 23))
    text(679, 218, "강호 인물 선택", white, 42)
    return
  elseif picid == 262 then
    fill(411, 31, 1018, 187, RGB(76, 48, 25))
    text(714, 70, "금서군협전", gold, 58)
    return
  elseif picid == 408 then
    fill(368, 96, 1070, 231, black)
    text(719, 124, "금서군협전", gold, 58)
    return
  end

  if picid == 566 then
    fill(29, 20, 86, 102, black)
    text(58, 28, "동*료", white, 29)
    return
  end

  local yellowTabs = {[550]=1, [552]=2, [554]=3, [620]=4, [1126]=5}
  local redTabs = {[728]=1, [730]=2, [732]=3, [734]=4, [1128]=5}
  local selected = yellowTabs[picid] or redTabs[picid]
  if selected then
    local labels = {"능*력*치", "무*공", "비*기", "경*맥", "전*투"}
    local top = {184, 289, 397, 506, 618}
    local selectedColor = yellowTabs[picid] and (C_YELLOW or gold) or (C_RED or RGB(255, 0, 0))
    for i = 1, 5 do
      fill(1302, top[i], 1359, top[i] + 91, black)
      text(1330, top[i] + 8, labels[i], (i == selected) and selectedColor or white, (i == 1) and 23 or 29)
    end
    return
  end

  local titles = {[556]="능력치", [558]="무공", [622]="비기", [560]="경맥", [1124]="전투"}
  local title = titles[picid]
  if title then
    fill(866, 224, 960, 300, black)
    text(913, 237, title, white, (#utf8chars(title) == 3) and 27 or 38)
  end

  if picid == 558 or picid == 622 then
    local noun = (picid == 558) and "무공" or "비기"
    fill(582, 684, 666, 721, dark)
    fill(658, 706, 922, 744, dark)
    text(624, 686, "새 " .. noun, white, 23)
    text(790, 711, "X키: 새 " .. noun .. " 습득", gold, 18)
    if picid == 558 then
      fill(1157, 672, 1211, 742, dark)
      text(1184, 681, "무공*숙련", gold, 19)
    end
  elseif picid == 1124 then
    fill(778, 323, 1047, 370, dark)
    text(913, 327, "자동 전투 설정", gold, 31)
    local rows = {
      {389, "초식 방침", "분노가 충분하면 선택한 초식을 우선 사용"},
      {463, "공격 방침", "전투 중 자동으로 사용할 주 공격 방침"},
      {537, "약물 방침", "전투 중 자동으로 사용할 주 약물 방침"},
      {611, "부활 방침", "아군 생명력이 기준치 아래로 내려가면 부활 내공으로 전환"},
    }
    for i = 1, #rows do
      local row = rows[i]
      fill(568, row[1] - 2, 701, row[1] + 34, dark)
      fill(599, row[1] + 31, 1200, row[1] + 58, dark)
      text(580, row[1], row[2], white, 24, CC.FONT2, "left")
      text(608, row[1] + 34, row[3], white, 14, CC.FONT3, "left")
    end
  end
end

-- The engine formats some vertical counters through NumberToChinese even
-- though they are ordinary quantities (30 -> "三0", 1800 -> "一八00").
-- Normalize only strings made entirely of Chinese/Arabic numeral glyphs
-- before DrawStringVertical splits them into individual characters.  Names
-- and other vertical labels continue through the normal translation path.
if type(DrawStringVertical) == "function" then
  local originalDrawStringVertical = DrawStringVertical
  DrawStringVertical = function(x, y, str, ...)
    local value = tostring(str or "")
    local numeric = display_number(value)
    if numeric then str = numeric end
    return originalDrawStringVertical(x, y, str, ...)
  end
end

if type(lib.DrawStr) == "function" then
  local originalDrawStr = lib.DrawStr
  -- 일부 전투 아이콘은 이름을 통문장이 아니라 한 글자씩 DrawStr에 넘긴다.
  -- 자주 쓰이는 무공/상태명 글자도 여기서 보정해야 "양明" 같은 반쪽 번역이 남지 않는다.
  local verticalGlyph = {
    ["西"]="서", ["部"]="부", ["海"]="해", ["外"]="외", ["岛"]="섬", ["屿"]="",
    ["陽"]="양", ["阳"]="양", ["明"]="명", ["地"]="지", ["火"]="화",
    ["聖"]="성", ["圣"]="성", ["北"]="북", ["斗"]="두", ["九"]="구",
    ["慕"]="모", ["容"]="용", ["四"]="사", ["象"]="상",
    ["必"]="필", ["技"]="기", ["対"]="대", ["對"]="대", ["对"]="대",
    ["男"]="남", ["性"]="성", ["瑜"]="유", ["伽"]="가",
    -- 전투/인물 아이콘은 명칭을 한 글자씩 그리므로 한자 음독으로 보정한다.
    ["打"]="타", ["狗"]="구", ["陰"]="음", ["阴"]="음",
    ["靈"]="영", ["灵"]="영", ["犀"]="서", ["十"]="십", ["方"]="방",
    ["梁"]="양", ["雲"]="운", ["云"]="운", ["萬"]="만", ["万"]="만",
    ["蠱"]="고", ["蛊"]="고", ["體"]="체", ["体"]="체",
    -- 저장/날짜 화면도 숫자와 단위를 글자별로 출력한다.
    ["一"]="일", ["二"]="이", ["三"]="삼", ["五"]="오", ["六"]="육",
    ["七"]="칠", ["八"]="팔", ["時"]="시", ["时"]="시",
    ["間"]="간", ["间"]="간", ["長"]="간", ["长"]="간", ["秒"]="초",
    ["年"]="년", ["月"]="월", ["日"]="일", ["玄"]="현",
    ["父"]="부", ["母"]="모"
  }
  lib.DrawStr = function(x, y, str, ...)
    local translated = verticalGlyph[str]
    if translated == nil then translated = KOTR(str) end
    return originalDrawStr(x, y, translated, ...)
  end
end

local fixedPngDimensions = {
  [2]={1360,768}, [4]={1360,768}, [124]={92,65}, [130]={67,56}, [198]={23,49}, [220]={1360,768},
  [340]={19,19}, [342]={19,19}, [344]={19,19}, [346]={19,19}, [348]={19,19}, [350]={19,19},
  [354]={19,19}, [356]={19,19}, [358]={19,19}, [360]={19,19}, [362]={19,19}, [382]={1360,768}, [414]={92,65},
  [418]={356,168}, [420]={356,168}, [444]={100,100}, [548]={132,12}, [726]={33,53},
  [1006]={1360,71}, [1008]={67,56}, [1010]={67,56}, [1074]={936,702}, [1088]={67,56},
  [1112]={93,47}, [1118]={730,473},
}

local function fixed_png_geometry(picid, x, y, ...)
  local size = fixedPngDimensions[picid]
  local width, height
  if size then
    width, height = size[1], size[2]
  elseif type(lib.GetPNGXY) == "function" then
    width, height = lib.GetPNGXY(91, picid)
  end
  width, height = width or 0, height or 0
  local percent = select(3, ...)
  local zoom = (type(percent) == "number" and percent > 0) and percent / 100 or 1
  local mode = select(1, ...)
  local ox, oy = x, y
  if mode == 2 then
    ox = x - width * zoom / 2
    oy = y - height * zoom / 2
  end
  return ox, oy, width * zoom, height * zoom, zoom
end

local function localize_fixed_png(picid, x, y, ...)
  if type(DrawString) ~= "function" then return end
  if not fixedPngDimensions[picid] then return end
  local ox, oy, width, height, zoom = fixed_png_geometry(picid, x, y, ...)
  local black = C_BLACK or RGB(0, 0, 0)
  local white = C_WHITE or RGB(255, 255, 255)
  local red = C_RED or RGB(255, 0, 0)
  local gold = C_GOLD or RGB(255, 215, 0)
  local function fill(x1, y1, x2, y2, color)
    lib.Background(ox + x1 * zoom, oy + y1 * zoom, ox + x2 * zoom, oy + y2 * zoom, 0, color)
  end
  local function text(rx, ry, value, color, size, font, align)
    DrawString(ox + rx * zoom, oy + ry * zoom, value, color, size * zoom, font or CC.FONT2, align or "center", 1)
  end

  local hudLabels = {[1010]="정*보", [1008]="지*도", [130]="도*감", [1088]="임*무"}
  local hudLabel = hudLabels[picid]
  if hudLabel then
    fill(11, 1, 49, 45, black)
    text(30, 3, hudLabel, white, 15)
    return
  end

  local badgeLabels = {
    [340]={"권", RGB(231, 177, 36), black}, [342]={"지", RGB(52, 78, 210), white},
    [344]={"검", RGB(35, 156, 213), white}, [346]={"도", RGB(184, 24, 31), white},
    [348]={"기", RGB(198, 49, 183), white}, [350]={"내", RGB(30, 39, 91), white},
    [354]={"송", RGB(147, 208, 219), black}, [356]={"원", RGB(117, 76, 54), white},
    [358]={"명", RGB(218, 92, 185), black}, [360]={"청", RGB(203, 198, 199), black},
    [362]={"기", RGB(215, 74, 51), white},
  }
  local badge = badgeLabels[picid]
  if badge then
    fill(0, 0, 19, 19, badge[2])
    text(9.5, 1, badge[1], badge[3], 15)
    return
  end

  if picid == 124 or picid == 414 then
    fill(0, 0, 31, 65, RGB(28, 28, 28))
    text(15, 7, "보*상", red, 19)
  elseif picid == 198 then
    fill(0, 0, 23, 49, RGB(167, 23, 23))
    text(11.5, 4, "운*용", white, 16)
  elseif picid == 418 then
    fill(0, 43, 31, 121, black)
    text(15, 48, "조*건", red, 18)
  elseif picid == 420 then
    text(width / zoom / 2, height / zoom / 2 - 20, "미활성", red, 34)
  elseif picid == 444 then
    text(width / zoom / 2, height / zoom / 2 - 14, "품절", red, 24)
  elseif picid == 548 then
    fill(0, 0, 132, 12, RGB(22, 27, 34))
    text(66, 0, "천하무공, 오직 빠름뿐", white, 9)
  elseif picid == 726 then
    fill(0, 0, 33, 53, RGB(142, 16, 24))
    text(16.5, 5, "혈*도", white, 17)
  elseif picid == 1006 then
    fill(0, 0, 1360, 70, RGB(245, 245, 245))
    text(67, 20, "번호", black, 24)
    text(160, 20, "진행", black, 24, CC.FONT2, "left")
    text(1025, 20, "보상", black, 24, CC.FONT2, "left")
  elseif picid == 1074 then
    fill(10, 13, 926, 48, RGB(40, 22, 12))
    local tabs = {
      {65, "객잔/도시"}, {201, "강호 방파Ⅰ"}, {337, "강호 방파Ⅱ"}, {475, "인물 거처"},
      {607, "명산대천"}, {742, "동굴/섬"}, {868, "기타 장소"},
    }
    for i = 1, #tabs do text(tabs[i][1], 20, tabs[i][2], gold, 14) end
  elseif picid == 1112 then
    fill(0, 0, 93, 47, RGB(63, 47, 27))
    text(46.5, 10, "강호 소문", white, 18)
  elseif picid == 1118 then
    fill(220, 0, 510, 58, RGB(55, 59, 52))
    text(365, 9, "게임 환경 설정", gold, 27)
  elseif picid == 220 then
    fill(455, 20, 600, 365, RGB(105, 115, 92))
    text(527, 48, "금*서*군*협*전", black, 35)
    fill(112, 230, 270, 435, RGB(91, 105, 82))
    text(191, 277, "교*혜", black, 34)
    fill(845, 18, 945, 112, RGB(112, 122, 99))
    text(895, 35, "금*서", black, 24)
  elseif picid == 382 then
    fill(365, 72, 995, 245, RGB(35, 66, 99))
    text(680, 111, "금서군협전", gold, 58)
  elseif picid == 2 then
    fill(500, 85, 860, 255, RGB(78, 53, 27))
    text(680, 112, "승리", gold, 82)
  elseif picid == 4 then
    fill(505, 85, 855, 255, RGB(57, 42, 25))
    text(680, 112, "패배", gold, 82)
    fill(275, 350, 1045, 535, RGB(25, 22, 19))
    text(660, 393, "강호에서 다시 만나자!", red, 58)
  end
end

if type(lib.LoadPNG) == "function" then
  local originalLoadPNG = lib.LoadPNG
  lib.LoadPNG = function(resid, picid, x, y, ...)
    ensure_runtime_hooks()
    local suppressOriginal = resid == 91 and (picid == 420 or picid == 444)
    local result
    if not suppressOriginal then result = originalLoadPNG(resid, picid, x, y, ...) end
    if resid == 91 then
      if x == -1 and y == -1 then localize_character_ui(picid) end
      localize_fixed_png(picid, x, y, ...)
    end
    return result
  end
end

local mapLabels = {[58]="북부", [60]="서부", [62]="중원", [64]="강남", [66]="해외"}

local function localize_cached_map(picid, x, y)
  local label = mapLabels[picid]
  if not label or x ~= -1 or y ~= -1 or type(DrawString) ~= "function" then return end
  local bx, by = (CC and CC.WX) or 1, (CC and CC.HY) or 1
  local scale = math.min(bx, by)
  lib.Background(605 * bx, 34 * by, 755 * bx, 91 * by, 0, RGB(22, 28, 39))
  DrawString(680 * bx, 43 * by, label, C_GOLD or RGB(255, 215, 0), 35 * scale, CC.FONT2, "center", 1)
end

-- data/bj 메뉴 버튼 현지화.
-- 원본 한자 그림(2~28.png) 대신 글자 없는 0.png 원형을 그리고,
-- FIX127 한국어 패치와 같은 위치·크기·선택 색상으로 한글을 올린다.
local bjMenuLabels = {
  [4]="인물", [6]="가방", [8]="비급", [10]="설정",
  [12]="상태", [14]="정렬", [16]="이탈",
  [32]="전체", [34]="줄거리", [36]="장비", [38]="영약", [40]="암기",
  [42]="불러오기", [44]="저장", [46]="음악", [48]="효과음",
  [50]="정리", [52]="업적", [54]="코드", [56]="나가기",
}

if type(lib.PicLoadCache) == "function" then
  local originalPicLoadCache = lib.PicLoadCache
  lib.PicLoadCache = function(resid, picid, x, y, ...)
    local menuLabel = resid == 92 and bjMenuLabels[picid]
    if menuLabel and type(DrawString) == "function" then
      local mode, alpha = select(1, ...), select(2, ...)
      local originalScale = select(4, ...)
      local large = picid >= 4 and picid <= 10
      local nominal = large and 120 or 100
      local bx = (type(originalScale) == "number" and originalScale > 0)
        and originalScale / nominal or ((CC and CC.WX) or 1)
      local iconScale = bx * (large and 50 or 37)
      local selected = mode == 2
      local color = selected and (C_GOLD or RGB(255, 215, 0)) or RGB(175, 175, 175)
      local size = (large and CC.DefaultFont * 0.95 or CC.DefaultFont * 0.72) * bx
      local result = originalPicLoadCache(resid, 0, x, y, mode, alpha, nil, iconScale)
      DrawString(x, y - size / 2, menuLabel, color, size, CC.FONT2, "center", 1)
      return result
    end
    local result = originalPicLoadCache(resid, picid, x, y, ...)
    if resid == 92 then localize_cached_map(picid, x, y) end
    if resid == 1 and picid == 3024 and type(DrawString) == "function" then
      local zoom = (select(8, ...) or 100) / 100
      lib.Background(x + 43 * zoom, y + 50 * zoom, x + 101 * zoom, y + 81 * zoom, 0, RGB(0, 25, 0))
      DrawString(x + 72 * zoom, y + 56 * zoom, "빈자리", C_WHITE, 15 * zoom, CC.FONT3, "center")
    end
    return result
  end
end

return KOTR
