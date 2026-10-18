--[[
  Sol's RNG - Biome Macro   (original author: gustaslaoq)
  v4.0 - modified by GYESG:
    - New biomes: LOST FOREST and THE RADIANT FOREST, plus automatic learning of unknown biome names
    - UI colour changer (Settings > UI COLOR) and Thai / English interface (Settings > Language)
    - Faster walking (smarter path search + straighter routes), faster start-up, optional FPS boost
    - Fixed: two broken `goto` spots rebuilt so the script runs on Roblox/Luau
  Note: the Dashboard parts still talk to the author's server exactly as in the original.
]]

local players = game:GetService("Players")
local tweenService = game:GetService("TweenService")
local coreGui = game:GetService("CoreGui")
local httpService = game:GetService("HttpService")
local textChatService = game:GetService("TextChatService")
local teleportService = game:GetService("TeleportService")
local runService = game:GetService("RunService")
local virtualInputManager = game:GetService("VirtualInputManager")
local guiService = game:GetService("GuiService")
local pathfindingService = game:GetService("PathfindingService")
local userInputService = game:GetService("UserInputService")
local virtualUser = game:GetService("VirtualUser")
local statsService = game:GetService("Stats")
getgenv().MacroRunning = getgenv().MacroRunning or false

if not game:IsLoaded() then
  game.Loaded:Wait()
end

local localPlayer = players.LocalPlayer

repeat
  task.wait()
until localPlayer

repeat
  task.wait()
until localPlayer.Character

localPlayer:FindFirstChild("PlayerGui")
local v1

repeat
  task.wait()
  v1 = localPlayer
until v1:FindFirstChild("PlayerGui")

local playerGui = localPlayer:WaitForChild("PlayerGui")
local v2 = ({ [3160474349] = true, [5247001245] = true })[localPlayer.UserId]
local v3 = { forcedBiome = nil, forcedMerchant = nil }
local v4 = false

local function makeScreenGui()
  if pcall(function()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Parent = playerGui
    screenGui:Destroy()
  end) then
    return playerGui
  end

  return coreGui
end

local v5 = makeScreenGui()

if not v5 then
  error("GuiParent not found")
  return
end

if _G.__BIOME_LAST_JOBID ~= game.JobId then
  _G.__BIOME_LAST_JOBID = game.JobId
  _G.__BIOME_SCRIPT_EXECUTED = false
  _G.__BIOME_SCRIPT_LOADING = false
  _G.__BIOME_SCRIPT_UNLOADING = false
  _G.__BiomeNotifSystem = nil
end

if not _G.__BiomeNotifSystem then
  _G.__BiomeNotifSystem = { Gui = nil, Active = {}, Counter = 0 }
end

local biomeNotifSystem = _G.__BiomeNotifSystem

if not biomeNotifSystem.Counter then
  biomeNotifSystem.Counter = 0
end

if not biomeNotifSystem.Active then
  biomeNotifSystem.Active = {}
end

function getNotifyGui()
  if biomeNotifSystem.Gui and biomeNotifSystem.Gui.Parent then
    return biomeNotifSystem.Gui
  else
    local v6 = Instance.new("ScreenGui")
    v6.Name = "notify"
    v6.IgnoreGuiInset = true
    v6.ResetOnSpawn = false
    v6.Parent = v5

    biomeNotifSystem.Gui = v6
    return v6
  end
end

function updatePositions()
  local v7 = {}

  for index, value in ipairs(biomeNotifSystem.Active) do
    if not value.IsRemoving and value.Label and value.Label.Parent then
      v7[#v7 + 1] = value
    end
  end

  for index2, value2 in ipairs(v7) do
    local v8 = 0.05 + (index2 - 1) * 0.055

    if value2.MoveTween then
      value2.MoveTween:Cancel()
    end

    value2.MoveTween = tweenService:Create(value2.Label, TweenInfo.new(
      0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out
    ), { Position = UDim2.fromScale(0.5, v8) })

    value2.MoveTween:Play()
  end

  if #biomeNotifSystem.Active == 0 and biomeNotifSystem.Gui then
    biomeNotifSystem.Gui:Destroy()
    biomeNotifSystem.Gui = nil
  end
end

function notify(text, p1)
  local color = p1 or Color3.fromRGB(255, 255, 255)
  local textLabel, v9

  if #biomeNotifSystem.Active >= 8 then
    return
  else
    local parent = getNotifyGui()

    if type(biomeNotifSystem.Counter) ~= "number" then
      biomeNotifSystem.Counter = 0
    end

    biomeNotifSystem.Counter = biomeNotifSystem.Counter + 1

    textLabel = Instance.new("TextLabel")
    textLabel.Name = "notification" .. tostring(biomeNotifSystem.Counter)
    textLabel.AnchorPoint = Vector2.new(0.5, 0)
    textLabel.Position = UDim2.fromScale(0.5, -0.15)
    textLabel.Size = UDim2.fromScale(0.5, 0.04)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = color
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.Sarpanch
    textLabel.BorderSizePixel = 0
    textLabel.ZIndex = 100
    textLabel.Parent = parent

    local uiStroke = Instance.new("UIStroke")
    uiStroke.Color = Color3.fromRGB(0, 0, 0)
    uiStroke.Thickness = 1
    uiStroke.Transparency = 0.4
    uiStroke.Parent = textLabel

    v9 = { Label = textLabel, IsRemoving = false, MoveTween = nil }
    table.insert(biomeNotifSystem.Active, v9)

    tweenService:Create(textLabel, TweenInfo.new(
      0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out
    ), {
      Position = UDim2.fromScale(0.5, 0.05 + (#biomeNotifSystem.Active - 1) * 0.055),
    }):Play()

    task.delay(3, function()
      if not textLabel or not textLabel.Parent then
        return
      else
        v9.IsRemoving = true

        local create = tweenService:Create(textLabel, TweenInfo.new(
          0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In
        ), { Position = UDim2.fromScale(0.5, -0.15) })

        create:Play()

        create.Completed:Connect(function()
          if textLabel and textLabel.Parent then
            textLabel:Destroy()
          end

          for index3, value3 in ipairs(biomeNotifSystem.Active) do
            if value3.Label == textLabel then
              table.remove(biomeNotifSystem.Active, index3)
              break
            end
          end

          updatePositions()
        end)

        return
      end
    end)

    return
  end
end

function errorNotify(p2)
  notify(p2, Color3.fromRGB(193, 9, 9))
end

if _G.__BIOME_SCRIPT_EXECUTED then
  errorNotify("- Error: Script already executed in this session! -")
  error("Script execution blocked: Already executed in this session")
  return
end

if _G.__BIOME_SCRIPT_LOADING then
  errorNotify("- Error: Script is still loading, please wait! -")
  error("Script execution blocked: Loading in progress")
  return
end

_G.__BIOME_SCRIPT_LOADING = true

local f1, f2, f3, f4, configFilePath, userConfig, globalStats, v12, name, v13, macroRunning, v15, v16, v17, v18, v19, v20,
  v21, v22, v23, v24, v25, v26, v27, v28, v29, v30, v31, v32, v33, v34, v35, v36, v37, v38, v39,
  v40, v41, v42, v43, httpRequest, uiLibrary, v46, ui, v48, addStatusBadge2, addStatusBadge22, v49, v50, v51,
  v52, v53, v54, v55, v56, addInput, addInput2, addInput3, addInputNumber, addToggle, v57, v58,
  v59, addLogConsole, v60, addInputNumber2, addInputNumber3, addToggle2, addToggle3,
  addMultiSelect, addInputNumber4, addInputNumber5, v61, addActionList, f5, f6, autoWalk, v63, autoMerchant,
  inputHelper, v65, addInput4, v66, v67, af, v68, f7, v69, v70, v71, v72, v73, v74, v75, v76, v77, v78,
  v79, v80, v81, v82, v83, v84, v85, v86, v87, v88, v89

------------------------------------------------------------------------------
-- GYESG MOD v4  (original script: Slaoq's Biome Macro by gustaslaoq)
--   * Thai / English interface        (Settings > Language)
--   * UI colour changer               (Settings > UI COLOR)
--   * New biomes + automatic learning of biomes that are not in the table yet
--   * Faster walking (fewer path searches, straighter routes) + optional FPS boost
------------------------------------------------------------------------------
do
  if GYESG and GYESG.destroy then
    pcall(GYESG.destroy)
  end

  GYESG = { alive = true, conns = {}, libSet = {}, tries = {}, seen = {} }
  local GY = GYESG

  GY.TH = {
    ["Biome Macro"] = "มาโครไบโอม",
    ["Control"] = "ควบคุม",
    ["Macro State"] = "สถานะมาโคร",
    ["offline"] = "ออฟไลน์",
    ["Start"] = "เริ่ม",
    ["Stop"] = "หยุด",
    ["Private Server"] = "เซิร์ฟเวอร์ส่วนตัว",
    ["Private Server Link"] = "ลิงก์เซิร์ฟเวอร์ส่วนตัว",
    ["Permanent PS link (roblox.com/share?...)"] = "ลิงก์ PS ถาวร (roblox.com/share?...)",
    ["Webhooks"] = "เว็บฮุก",
    ["Add Webhook"] = "เพิ่มเว็บฮุก",
    ["Discord Webhook URL"] = "URL เว็บฮุก Discord",
    ["Saved Webhooks"] = "เว็บฮุกที่บันทึกไว้",
    ["Session"] = "เซสชัน",
    ["Anti-AFK"] = "กันหลุด (Anti-AFK)",
    ["Actions"] = "คำสั่ง",
    ["Stop and Rejoin"] = "หยุดและเข้าเกมใหม่",
    ["Unload"] = "ปิดสคริปต์",
    ["Status"] = "สถานะ",
    ["Live state of your current macro session"] = "สถานะสดของเซสชันมาโครตอนนี้",
    ["State"] = "สถานะการทำงาน",
    ["Session Timer"] = "เวลาเซสชัน",
    ["Elapsed Time"] = "เวลาที่ผ่านไป",
    ["Last Biome"] = "ไบโอมล่าสุด",
    ["Session Counts"] = "ตัวนับเซสชัน",
    ["Biomes Detected"] = "ไบโอมที่ตรวจพบ",
    ["Merchants Found"] = "พ่อค้าที่พบ",
    ["Event Log"] = "บันทึกเหตุการณ์",
    ["Statistics"] = "สถิติ",
    ["All-Time"] = "ตลอดกาล",
    ["Total Biomes"] = "ไบโอมทั้งหมด",
    ["Rare Biome Counters"] = "ตัวนับไบโอมหายาก",
    ["Per Biome"] = "แยกตามไบโอม",
    ["Pings"] = "การแจ้งเตือน (Ping)",
    ["Notifications, pings, and identification"] = "การแจ้งเตือน การ ping และการระบุตัวตน",
    ["Global Ping IDs"] = "ID ping ทั่วไป",
    ["User IDs to Ping"] = "User ID ที่จะ ping",
    ["ID1, ID2... (numbers only)"] = "ID1, ID2... (ตัวเลขเท่านั้น)",
    ["Role IDs to Ping"] = "Role ID ที่จะ ping",
    ["Role1, Role2... (numbers only)"] = "Role1, Role2... (ตัวเลขเท่านั้น)",
    ["Ping Threshold"] = "เกณฑ์ ping",
    ["Aura Rarity Ping Threshold"] = "เกณฑ์ความหายากของออร่าที่จะ ping",
    ["  -> Specific IDs for this event"] = "  -> ID เฉพาะสำหรับเหตุการณ์นี้",
    ["Biome Pings"] = "ping ไบโอม",
    ["How Pings work"] = "วิธีการทำงานของ ping",
    ["Merchant Pings"] = "ping พ่อค้า",
    ["Special Events"] = "อีเวนต์พิเศษ",
    ["Settings"] = "ตั้งค่า",
    ["PERFORMANCE"] = "ประสิทธิภาพ",
    ["Biome Scanner Interval (Seconds)"] = "ช่วงเวลาสแกนไบโอม (วินาที)",
    ["Performance Warning"] = "คำเตือนด้านประสิทธิภาพ",
    ["DISCORD & ANTI-SPAM"] = "DISCORD และกันสแปม",
    ["Muted Biomes"] = "ไบโอมที่ปิดเสียง",
    ["AUTO EXECUTE"] = "การรันอัตโนมัติ",
    ["Auto Execute"] = "รันอัตโนมัติ (Auto Execute)",
    ["Resumes Last State"] = "ทำต่อจากสถานะล่าสุด",
    ["ANTI-AFK"] = "ระบบกันหลุด",
    ["Execution Interval (Seconds)"] = "ช่วงเวลาทำงาน (วินาที)",
    ["AUTOMATION PATHFINDING"] = "ระบบเดินอัตโนมัติ",
    ["Debug Pathfinding"] = "แสดงเส้นทางดีบัก",
    ["Pathfinding Warning"] = "คำเตือนระบบเดิน",
    ["Automation"] = "ระบบอัตโนมัติ",
    ["BIOME RANDOMIZER"] = "ตัวสุ่มไบโอม",
    ["Enable SC/BR (Biome Randomizer)"] = "เปิด SC/BR (Biome Randomizer)",
    ["Use Interval (Minutes)"] = "ช่วงเวลาใช้งาน (นาที)",
    ["FISHING"] = "ตกปลา",
    ["Auto Fishing"] = "ตกปลาอัตโนมัติ",
    ["Continuously fishes automatically"] = "ตกปลาต่อเนื่องอัตโนมัติ",
    ["Fish Before Auto Sell"] = "จำนวนปลาก่อนขายอัตโนมัติ",
    ["Auto Sell"] = "ขายอัตโนมัติ",
    ["LIVE STATUS"] = "สถานะสด",
    ["Fish Count"] = "จำนวนปลา",
    ["SC/BR Timer"] = "ตัวจับเวลา SC/BR",
    ["Fishing State"] = "สถานะการตกปลา",
    ["AUTO POP"] = "ระบบ Auto Pop",
    ["Enable Auto Pop"] = "เปิด Auto Pop",
    ["Auto Pop"] = "ใช้ไอเทมอัตโนมัติ (Auto Pop)",
    ["Biome"] = "ไบโอม",
    ["Potion"] = "โพชั่น",
    ["Amount"] = "จำนวน",
    ["Add Item"] = "เพิ่มไอเทม",
    ["Remove Item"] = "ลบไอเทม",
    ["Clear Biome"] = "ล้างไบโอม",
    ["Configured Rules"] = "กฎที่ตั้งไว้",
    ["Active Rules"] = "กฎที่ใช้งานอยู่",
    ["AUTO MERCHANT"] = "ระบบซื้อของพ่อค้า",
    ["Enable Auto Merchant"] = "เปิดซื้อของพ่อค้าอัตโนมัติ",
    ["Auto Merchant"] = "ซื้อของพ่อค้าอัตโนมัติ",
    ["Merchant"] = "พ่อค้า",
    ["Item"] = "ไอเทม",
    ["Set to Max"] = "ตั้งเป็นสูงสุด",
    ["Add Purchase"] = "เพิ่มรายการซื้อ",
    ["Remove"] = "ลบ",
    ["Clear Merchant"] = "ล้างพ่อค้า",
    ["Merchant Purchases"] = "รายการซื้อของพ่อค้า",
    ["WORLD AUTOMATION"] = "ระบบอัตโนมัติในแมพ",
    ["Auto Reset On Rare Biome"] = "รีเซ็ตตัวละครอัตโนมัติเมื่อเจอไบโอมหายาก",
    ["Auto Obby Luck Boost"] = "เก็บบัพลัคจาก Obby อัตโนมัติ",
    ["Auto Collect Clover"] = "เก็บโคลเวอร์อัตโนมัติ",
    ["Auto Contract with Eden"] = "ทำสัญญากับ Eden อัตโนมัติ",
    ["Biome Counts"] = "จำนวนไบโอม",
    ["Update Log"] = "บันทึกการอัปเดต",
    ["Biome Randomizer"] = "Biome Randomizer (ตัวสุ่มไบโอม)",
    ["Main"] = "หน้าหลัก",
    ["Automatic biome and merchant detection for Sol's RNG"] = "ตรวจจับไบโอมและพ่อค้าอัตโนมัติสำหรับ Sol's RNG",
    ["Keeps player active to prevent disconnection"] = "ทำให้ผู้เล่นขยับอยู่เสมอ เพื่อป้องกันการหลุดจากเกม",
    ["Lifetime biome detection across all sessions"] = "ตรวจจับไบโอมสะสมตลอดทุกเซสชัน",
    ["These IDs are used as the default for every toggle below. Leave a toggle's custom field empty to use these globals."] = "ID เหล่านี้ใช้เป็นค่าเริ่มต้นของทุกสวิตช์ด้านล่าง หากเว้นช่องกำหนดเองของสวิตช์ไหนว่างไว้ จะใช้ค่าทั่วไปนี้",
    ["  Numbers = user IDs * r:prefix = role IDs * Empty = uses global IDs above"] = "  ตัวเลข = User ID * ขึ้นต้นด้วย r: = Role ID * ว่าง = ใช้ ID ทั่วไปด้านบน",
    ["The User/Role IDs above ping for **every** active toggle by default. To ping **only specific people** for a single event, activate its toggle and fill in the custom IDs field that appears below it. DREAMSPACE, GLITCHED and CYBERSPACE always ping @everyone and are not listed here."] = "User/Role ID ด้านบนจะถูก ping กับ **ทุก** สวิตช์ที่เปิดอยู่เป็นค่าเริ่มต้น หากต้องการ ping **เฉพาะบางคน** สำหรับเหตุการณ์เดียว ให้เปิดสวิตช์นั้นแล้วกรอก ID กำหนดเองในช่องที่ปรากฏด้านล่าง DREAMSPACE, GLITCHED และ CYBERSPACE จะ ping @everyone เสมอและไม่อยู่ในรายการนี้",
    ["Advanced macro behavior, notification filters, and collection system"] = "การทำงานขั้นสูงของมาโคร ตัวกรองการแจ้งเตือน และระบบเก็บของ",
    ["Increasing this interval significantly reduces CPU usage and lag on low-end devices or phones, but may cause a slight delay in detecting new biomes."] = "ยิ่งตั้งช่วงเวลานี้นานขึ้น ยิ่งลดการใช้ CPU และอาการหน่วงบนเครื่องสเปกต่ำหรือมือถือได้มาก แต่การตรวจจับไบโอมใหม่อาจช้าลงเล็กน้อย",
    ["Muted biomes are still counted in stats but won't send Discord notifications."] = "ไบโอมที่ปิดเสียงยังถูกนับในสถิติ แต่จะไม่ส่งแจ้งเตือนไปที่ Discord",
    ["Queues this script to run again after teleport or rejoin"] = "ตั้งให้สคริปต์นี้รันซ้ำอัตโนมัติหลังเทเลพอร์ตหรือเข้าเกมใหม่",
    ["When the script reruns via Auto Execute, it automatically returns to whatever state it was last in (e.g. if Start was active on the last teleport, it starts again automatically)."] = "เมื่อสคริปต์รันซ้ำด้วย Auto Execute จะกลับไปอยู่ในสถานะล่าสุดโดยอัตโนมัติ (เช่น ถ้าตอนเทเลพอร์ตครั้งก่อนกด Start ไว้ ก็จะเริ่มทำงานต่อเอง)",
    ["Shows only the active path line and waypoints while navigation is running"] = "แสดงเฉพาะเส้นทางและจุดเดินที่กำลังใช้อยู่ขณะระบบเดินทำงาน",
    ["Debug path objects are created locally in Workspace and are cleared as the character advances."] = "วัตถุดีบักของเส้นทางถูกสร้างฝั่งเครื่องคุณใน Workspace และจะถูกลบเมื่อตัวละครเดินผ่าน",
    ["Auto Fishing * Auto Sell * SC/BR Biome Randomizer"] = "ตกปลาอัตโนมัติ * ขายอัตโนมัติ * SC/BR Biome Randomizer",
    ["Uses Strange Controller and Biome Randomizer on a wall-clock timer. Turning fishing on keeps the existing timer instead of using items again."] = "ใช้ Strange Controller และ Biome Randomizer ตามเวลาจริง การเปิดตกปลาจะคงตัวจับเวลาเดิมไว้ ไม่ใช้ไอเทมซ้ำ",
    ["Automatically uses Strange Controller and Biome Randomizer at the set interval"] = "ใช้ Strange Controller และ Biome Randomizer อัตโนมัติตามช่วงเวลาที่ตั้งไว้",
    ["Casts automatically, completes the fishing minigame, tracks catches, and can sell once the configured target is reached."] = "ทอดเบ็ดอัตโนมัติ เล่นมินิเกมตกปลาให้จบ นับปลาที่ได้ และขายเมื่อถึงเป้าหมายที่ตั้งไว้",
    ["Automatically walks to NPC and sells fish when the catch target is reached"] = "เดินไปหา NPC และขายปลาอัตโนมัติเมื่อถึงเป้าหมายจำนวนปลา",
    ["Automatically uses configured potions when a matching biome is detected"] = "ใช้โพชั่นที่ตั้งไว้อัตโนมัติเมื่อตรวจพบไบโอมที่ตรงกัน",
    ["Select a biome, choose a potion and amount, then click Add Item. Fires once per biome occurrence."] = "เลือกไบโอม เลือกโพชั่นและจำนวน แล้วกด เพิ่มไอเทม จะทำงานหนึ่งครั้งต่อการเกิดไบโอมหนึ่งครั้ง",
    ["Automatically buys configured items when a selected merchant is found"] = "ซื้อไอเทมที่ตั้งไว้อัตโนมัติเมื่อพบพ่อค้าที่เลือก",
    ["Select a merchant, choose an item and amount, then add it to the purchase list."] = "เลือกพ่อค้า เลือกไอเทมและจำนวน แล้วเพิ่มลงรายการซื้อ",
    ["Uses the shop's Set to Max button for the selected item"] = "ใช้ปุ่ม Set to Max ของร้านกับไอเทมที่เลือก",
    ["Instantly resets the character when GLITCHED, CYBERSPACE or DREAMSPACE is detected. Fires once per detection."] = "รีเซ็ตตัวละครทันทีเมื่อตรวจพบ GLITCHED, CYBERSPACE หรือ DREAMSPACE ทำงานหนึ่งครั้งต่อการตรวจพบ",
    ["Automatically collects the obby luck boost when it is ready"] = "เก็บบัพลัคจาก Obby อัตโนมัติเมื่อพร้อม",
    ["Automatically collects clovers found in the map"] = "เก็บโคลเวอร์ที่พบในแมพอัตโนมัติ",
    ["Waits for Eden, enters Limbo if needed, then contracts with Eden automatically"] = "รอ Eden เข้า Limbo หากจำเป็น แล้วทำสัญญากับ Eden อัตโนมัติ",
    ["WALKING & PERFORMANCE"] = "การเดินและประสิทธิภาพ",
    ["Fast Walk (smart paths)"] = "เดินเร็ว (เส้นทางฉลาดขึ้น)",
    ["Fewer path searches and straighter routes, so the character walks faster"] = "ค้นหาเส้นทางน้อยครั้งลงและเดินตรงขึ้น ตัวละครจึงเดินได้เร็วขึ้น",
    ["FPS Boost (lower graphics)"] = "เพิ่ม FPS (ลดกราฟิก)",
    ["Lowers quality, shadows and particle effects to reduce lag. Turn off to restore."] = "ลดคุณภาพภาพ เงา และเอฟเฟกต์อนุภาค เพื่อลดอาการหน่วง ปิดเพื่อคืนค่าเดิม",
    ["Most texts change right away; the rest update on the next run."] = "ข้อความส่วนใหญ่เปลี่ยนทันที ที่เหลือจะเปลี่ยนเมื่อรันสคริปต์ครั้งถัดไป",
    ["UI COLOR"] = "สีของ UI",
    ["Theme color"] = "สีธีม",
    ["Custom color (HEX)"] = "กำหนดสีเอง (HEX)",
    ["online"] = "ออนไลน์",
    ["Idle"] = "ว่าง",
    ["Moving"] = "กำลังเดิน",
    ["Pathing"] = "กำลังหาเส้นทาง",
    ["Scanning"] = "กำลังสแกน",
    ["Waiting"] = "กำลังรอ",
    ["Starting"] = "กำลังเริ่ม",
    ["Paused"] = "หยุดชั่วคราว",
  }

  GY.NOTE = {
    ["Error: Failed to load UI library"] = "ผิดพลาด: โหลดไลบรารี UI ไม่สำเร็จ",
    ["Error: Invalid Webhook URL!"] = "ผิดพลาด: URL เว็บฮุกไม่ถูกต้อง!",
    ["Error: Maximum webhooks is 10"] = "ผิดพลาด: เพิ่มเว็บฮุกได้สูงสุด 10 อัน",
    ["Error: No Webhook configured!"] = "ผิดพลาด: ยังไม่ได้ตั้งเว็บฮุก!",
    ["Error: Script already executed in this session!"] = "ผิดพลาด: สคริปต์ถูกรันไปแล้วในเซสชันนี้!",
    ["Error: Script is still loading, please wait!"] = "ผิดพลาด: สคริปต์ยังโหลดอยู่ กรุณารอสักครู่!",
    ["Error: Script only works on Sols RNG"] = "ผิดพลาด: สคริปต์ใช้ได้เฉพาะใน Sols RNG",
    ["Invalid webhook URL"] = "URL เว็บฮุกไม่ถูกต้อง",
    ["Webhook already added"] = "เพิ่มเว็บฮุกนี้ไปแล้ว",
    ["SC/BR: Failed to open inventory"] = "SC/BR: เปิดช่องเก็บของไม่สำเร็จ",
    ["SC/BR: Inventory UI not found"] = "SC/BR: ไม่พบหน้าต่างช่องเก็บของ",
    ["/start: Macro Starting"] = "/start: กำลังเริ่มมาโคร",
    ["/start: Macro already running"] = "/start: มาโครกำลังทำงานอยู่แล้ว",
    ["/stop: Macro Stopped"] = "/stop: หยุดมาโครแล้ว",
    ["/test: All webhooks working"] = "/test: เว็บฮุกทุกอันใช้งานได้",
    ["/test: No valid webhook configured"] = "/test: ไม่มีเว็บฮุกที่ใช้งานได้",
    ["/test: Testing Webhook..."] = "/test: กำลังทดสอบเว็บฮุก...",
    ["Auto Execute: Resuming last state (Start)"] = "Auto Execute: กลับสู่สถานะล่าสุด (Start)",
    ["Auto Obby Luck Boost collected"] = "เก็บบัพลัคจาก Obby แล้ว",
    ["Clover collected"] = "เก็บโคลเวอร์แล้ว",
    ["Contracted with Eden"] = "ทำสัญญากับ Eden แล้ว",
    ["Eden Spawned in the limbo"] = "Eden เกิดใน Limbo แล้ว",
    ["Entered The Limbo: Chat Detection Active"] = "เข้า The Limbo แล้ว: เปิดตรวจจับแชท",
    ["Auto Collect Clover: Enabled"] = "เก็บโคลเวอร์อัตโนมัติ: เปิด",
    ["Auto Collect Clover: Disabled"] = "เก็บโคลเวอร์อัตโนมัติ: ปิด",
    ["Auto Contract with Eden: Enabled"] = "ทำสัญญากับ Eden อัตโนมัติ: เปิด",
    ["Auto Contract with Eden: Disabled"] = "ทำสัญญากับ Eden อัตโนมัติ: ปิด",
    ["Auto Fishing: Enabled"] = "ตกปลาอัตโนมัติ: เปิด",
    ["Auto Fishing: Disabled"] = "ตกปลาอัตโนมัติ: ปิด",
    ["Auto Merchant: Enabled"] = "ซื้อของพ่อค้าอัตโนมัติ: เปิด",
    ["Auto Merchant: Disabled"] = "ซื้อของพ่อค้าอัตโนมัติ: ปิด",
    ["Auto Obby Luck Boost: Enabled"] = "เก็บบัพลัคจาก Obby อัตโนมัติ: เปิด",
    ["Auto Obby Luck Boost: Disabled"] = "เก็บบัพลัคจาก Obby อัตโนมัติ: ปิด",
    ["Auto Pop: Enabled"] = "Auto Pop: เปิด",
    ["Auto Pop: Disabled"] = "Auto Pop: ปิด",
    ["Auto Reset On Rare Biome: Enabled"] = "รีเซ็ตตัวละครอัตโนมัติเมื่อเจอไบโอมหายาก: เปิด",
    ["Auto Reset On Rare Biome: Disabled"] = "รีเซ็ตตัวละครอัตโนมัติเมื่อเจอไบโอมหายาก: ปิด",
    ["Auto Sell: Enabled"] = "ขายอัตโนมัติ: เปิด",
    ["Auto Sell: Disabled"] = "ขายอัตโนมัติ: ปิด",
    ["UI color reset"] = "คืนค่าสี UI แล้ว",
    ["UI color: could not find the accent color"] = "สี UI: ไม่พบสีหลักของหน้าต่าง",
    ["Invalid color. Use a HEX code like #3B82F6"] = "สีไม่ถูกต้อง ใช้รหัส HEX เช่น #3B82F6",
  }

  GY.NOTE_PREFIX = {
    ["New biome learned: "] = "เรียนรู้ไบโอมใหม่: ",
    ["UI color: "] = "สี UI: ",
    ["Biome detected: "] = "ตรวจพบไบโอม: ",
    ["Biome ended: "] = "ไบโอมจบแล้ว: ",
    ["Aura Detected: "] = "ตรวจพบออร่า: ",
    ["Auto Merchant: Added "] = "ซื้อของพ่อค้าอัตโนมัติ: เพิ่ม ",
    ["Auto Pop: Cleared rules for "] = "Auto Pop: ล้างกฎของ ",
    ["Inventory item failed: "] = "ไอเทมในช่องเก็บของล้มเหลว: ",
    ["Account Suspended: "] = "บัญชีถูกระงับ: ",
  }

  ---------------------------------------------------------------- language
  function GY.lang()
    if type(userConfig) == "table" and userConfig.Language == "th" then
      return "th"
    end

    return "en"
  end

  function GY.T(text)
    if type(text) == "string" and GY.lang() == "th" then
      return GY.TH[text] or text
    end

    return text
  end

  function GY.translateNotice(text)
    if type(text) ~= "string" or GY.lang() ~= "th" then
      return text
    end

    local inner = text:match("^%- (.*) %-$")

    if inner then
      local exact = GY.NOTE[inner]

      if exact then
        return "- " .. exact .. " -"
      end

      for prefix, thai in pairs(GY.NOTE_PREFIX) do
        if inner:sub(1, #prefix) == prefix then
          return "- " .. thai .. inner:sub(#prefix + 1) .. " -"
        end
      end

      return text
    end

    local body = text:match("^%- (.*)$")

    if body then
      for prefix, thai in pairs(GY.NOTE_PREFIX) do
        if body:sub(1, #prefix) == prefix then
          return "- " .. thai .. body:sub(#prefix + 1)
        end
      end
    end

    return text
  end

  local TEXT_FIELDS = { Text = true, Placeholder = true, Label = true, Title = true, Description = true }

  local function translateFields(tbl, depth)
    if type(tbl) ~= "table" or depth > 3 then
      return
    end

    for key, value in pairs(tbl) do
      if type(value) == "string" then
        if TEXT_FIELDS[key] then
          tbl[key] = GY.T(value)
        end
      elseif type(value) == "table" then
        translateFields(value, depth + 1)
      end
    end
  end

  function GY.setLanguage(choice)
    if type(choice) ~= "string" then
      return
    end

    local code = (choice:find("Thai", 1, true) or choice:find("ไทย", 1, true)) and "th" or "en"

    if code == GY.lang() then
      return
    end

    userConfig.Language = code
    pcall(SaveData)
    pcall(GY.retranslate)

    if code == "th" then
      notify("- เปลี่ยนเป็นภาษาไทยแล้ว (บางข้อความจะเปลี่ยนเมื่อรันสคริปต์ใหม่) -")
    else
      notify("- Language set to English (some texts change on the next run) -")
    end
  end

  ---------------------------------------------------------------- finding the library window
  local function guiRoots()
    local roots = { coreGui, playerGui }

    if type(gethui) == "function" then
      local ok, hidden = pcall(gethui)

      if ok and hidden then
        roots[#roots + 1] = hidden
      end
    end

    return roots
  end

  function GY.snapshotGuis()
    local set = {}

    for _, root in ipairs(guiRoots()) do
      local ok, kids = pcall(function() return root:GetChildren() end)

      if ok then
        for _, gui in ipairs(kids) do
          set[gui] = true
        end
      end
    end

    return set
  end

  function GY.libGuis()
    local out = {}

    for gui in pairs(GY.libSet) do
      if gui.Parent then
        out[#out + 1] = gui
      else
        GY.libSet[gui] = nil
      end
    end

    return out
  end

  -- the library's ScreenGui is the new one that shows the app name "Biome Script"
  function GY.discover()
    if not GY.before then
      return
    end

    for gui in pairs(GY.snapshotGuis()) do
      if not GY.before[gui] and not GY.libSet[gui] and gui:IsA("ScreenGui") and gui.Name ~= "notify" then
        local tries = GY.tries[gui] or 0

        if tries < 12 then
          GY.tries[gui] = tries + 1

          for _, obj in ipairs(gui:GetDescendants()) do
            if obj:IsA("TextLabel") and obj.Text:lower():find("biome script", 1, true) then
              GY.libSet[gui] = true
              break
            end
          end
        end
      end
    end
  end

  function GY.startDiscovery()
    task.spawn(function()
      local started = tick()

      while GY.alive and tick() - started < 25 do
        pcall(GY.discover)
        task.wait(1)
      end
    end)
  end

  ---------------------------------------------------------------- live re-translation of existing labels
  function GY.retranslate()
    if not GY.rev then
      GY.rev = {}

      for english, thai in pairs(GY.TH) do
        GY.rev[thai] = english
      end
    end

    local toThai = GY.lang() == "th"

    local function convert(text)
      if type(text) ~= "string" or text == "" then
        return nil
      end

      if toThai then
        return GY.TH[text]
      end

      return GY.rev[text]
    end

    for _, gui in ipairs(GY.libGuis()) do
      for _, obj in ipairs(gui:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
          local new = convert(obj.Text)

          if new then
            obj.Text = new
          end
        elseif obj:IsA("TextBox") then
          local new = convert(obj.PlaceholderText)

          if new then
            obj.PlaceholderText = new
          end
        end
      end
    end
  end

  ---------------------------------------------------------------- UI colour changer
  -- The UI library has no theme option, so the accent colour is found at run time (the colour used
  -- most often) and every element that uses it - or a shade of it - is moved to the chosen colour.
  GY.Theme = { entries = {}, byInst = setmetatable({}, { __mode = "k" }), active = false, watching = false }
  local Theme = GY.Theme

  local COLOR_PROPS = {
    Frame = { "BackgroundColor3" },
    ScrollingFrame = { "BackgroundColor3", "ScrollBarImageColor3" },
    TextLabel = { "BackgroundColor3", "TextColor3" },
    TextButton = { "BackgroundColor3", "TextColor3" },
    TextBox = { "BackgroundColor3", "TextColor3" },
    ImageLabel = { "BackgroundColor3", "ImageColor3" },
    ImageButton = { "BackgroundColor3", "ImageColor3" },
    UIStroke = { "Color" },
  }

  GY.PRESETS = {
    { "Default", nil }, { "Blue", "#3B82F6" }, { "Purple", "#8B5CF6" }, { "Pink", "#EC4899" },
    { "Red", "#EF4444" }, { "Orange", "#F97316" }, { "Yellow", "#EAB308" }, { "Green", "#22C55E" },
    { "Cyan", "#06B6D4" }, { "White", "#E5E7EB" },
  }

  local function near(a, b)
    return math.abs(a.R - b.R) + math.abs(a.G - b.G) + math.abs(a.B - b.B) < 0.006
  end

  function Theme.hexToColor(hex)
    hex = tostring(hex or ""):gsub("^#", ""):gsub("%s", "")

    if #hex == 3 then
      hex = hex:gsub(".", "%0%0")
    end

    if not hex:match("^%x%x%x%x%x%x$") then
      return nil
    end

    return Color3.fromRGB(tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16))
  end

  function Theme.colorToHex(color)
    return string.format("#%02X%02X%02X", math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5),
      math.floor(color.B * 255 + 0.5))
  end

  function Theme.map(color)
    local base, target = Theme.base, Theme.target

    if not base or not target then
      return color
    end

    local h, s, v = color:ToHSV()

    if s < 0.25 or v < 0.2 then
      return color -- greys and very dark colours are not accent colours
    end

    local dh = h - base.h

    if dh > 0.5 then
      dh = dh - 1
    elseif dh < -0.5 then
      dh = dh + 1
    end

    if math.abs(dh) > 0.07 then
      return color -- a different colour family (danger / success / warning ...)
    end

    local nh = (target.h + dh) % 1
    local ns = math.clamp(s * (target.s / math.max(base.s, 0.05)), 0, 1)
    local nv = math.clamp(v * (target.v / math.max(base.v, 0.05)), 0, 1)
    return Color3.fromHSV(nh, ns, nv)
  end

  local function register(inst)
    local list = COLOR_PROPS[inst.ClassName]

    if not list then
      return 0
    end

    local per = Theme.byInst[inst]

    if not per then
      per = {}
      Theme.byInst[inst] = per
    end

    local added = 0

    for _, prop in ipairs(list) do
      if not per[prop] then
        local ok, color = pcall(function() return inst[prop] end)

        if ok and typeof(color) == "Color3" then
          local entry = { inst = inst, prop = prop, orig = color, cur = color }
          per[prop] = entry
          Theme.entries[#Theme.entries + 1] = entry
          added = added + 1

          if Theme.active then
            Theme.hook(entry)
            Theme.paint(entry)
          end
        end
      end
    end

    return added
  end

  function Theme.hook(entry)
    if entry.conn then
      return
    end

    local ok, signal = pcall(function() return entry.inst:GetPropertyChangedSignal(entry.prop) end)

    if not ok then
      return
    end

    entry.conn = signal:Connect(function()
      local read, now = pcall(function() return entry.inst[entry.prop] end)

      if not read or near(now, entry.cur) then
        return -- our own write
      end

      entry.orig = now -- the library changed it (animation / state change): keep following it
      local mapped = Theme.map(now)
      entry.cur = mapped

      if not near(now, mapped) then
        pcall(function() entry.inst[entry.prop] = mapped end)
      end
    end)
  end

  function Theme.paint(entry)
    local mapped = Theme.map(entry.orig)
    entry.cur = mapped

    local read, now = pcall(function() return entry.inst[entry.prop] end)

    if read and not near(now, mapped) then
      pcall(function() entry.inst[entry.prop] = mapped end)
    end
  end

  function Theme.detectBase()
    local counts, total = {}, {}

    for _, entry in ipairs(Theme.entries) do
      local h, s, v = entry.orig:ToHSV()

      if s >= 0.30 and v >= 0.35 then
        local key = string.format("%d,%d,%d", math.floor(entry.orig.R * 255 + 0.5), math.floor(entry.orig.G * 255 + 0.5),
          math.floor(entry.orig.B * 255 + 0.5))
        counts[key] = (counts[key] or 0) + 1
        total[key] = entry.orig
      end
    end

    -- group by hue (36 bins) and take the strongest group, then its most frequent exact colour
    local bins = {}

    for key, color in pairs(total) do
      local bin = math.floor((color:ToHSV()) * 36) % 36
      bins[bin] = (bins[bin] or 0) + counts[key]
    end

    local bestBin, bestScore = nil, 0

    for bin = 0, 35 do
      local score = (bins[bin] or 0) + 0.5 * (bins[(bin - 1) % 36] or 0) + 0.5 * (bins[(bin + 1) % 36] or 0)

      if score > bestScore then
        bestBin, bestScore = bin, score
      end
    end

    if not bestBin then
      return nil
    end

    local bestColor, bestCount = nil, 0

    for key, color in pairs(total) do
      local bin = math.floor((color:ToHSV()) * 36) % 36
      local dist = math.min((bin - bestBin) % 36, (bestBin - bin) % 36)

      if dist <= 1 and counts[key] > bestCount then
        bestColor, bestCount = color, counts[key]
      end
    end

    local h, s, v = bestColor:ToHSV()
    return { h = h, s = s, v = v, color = bestColor }
  end

  function Theme.scan()
    local added = 0

    for _, gui in ipairs(GY.libGuis()) do
      added = added + register(gui)

      for _, obj in ipairs(gui:GetDescendants()) do
        added = added + register(obj)
      end
    end

    return added
  end

  function Theme.watch()
    if Theme.watching then
      return
    end

    Theme.watching = true
    Theme.queue = {}

    for _, gui in ipairs(GY.libGuis()) do
      local ok, connection = pcall(function()
        return gui.DescendantAdded:Connect(function(obj)
          Theme.queue[#Theme.queue + 1] = obj

          if not Theme.flushing then
            Theme.flushing = true

            task.delay(0.3, function()
              Theme.flushing = false
              local batch = Theme.queue
              Theme.queue = {}

              for _, item in ipairs(batch) do
                if item.Parent then
                  pcall(register, item)
                end
              end
            end)
          end
        end)
      end)

      if ok and connection then
        GY.conns[#GY.conns + 1] = connection
      end
    end
  end

  function Theme.prune()
    local kept = {}

    for _, entry in ipairs(Theme.entries) do
      if entry.inst.Parent then
        kept[#kept + 1] = entry
      elseif entry.conn then
        entry.conn:Disconnect()
        entry.conn = nil
      end
    end

    Theme.entries = kept
  end

  function Theme.apply(color)
    if #Theme.entries == 0 then
      Theme.scan()
    end

    if not Theme.base then
      Theme.base = Theme.detectBase()
    end

    if not Theme.base then
      return false
    end

    Theme.prune()

    local h, s, v = color:ToHSV()
    Theme.target = { h = h, s = s, v = v }
    Theme.active = true

    for _, entry in ipairs(Theme.entries) do
      Theme.hook(entry)
      Theme.paint(entry)
    end

    Theme.watch()
    return true
  end

  function Theme.reset()
    Theme.active = false
    Theme.target = nil

    for _, entry in ipairs(Theme.entries) do
      if entry.conn then
        entry.conn:Disconnect()
        entry.conn = nil
      end

      if entry.inst.Parent then
        pcall(function() entry.inst[entry.prop] = entry.orig end)
      end

      entry.cur = entry.orig
    end
  end

  -- hex = "#RRGGBB" or nil / "default"
  function GY.setUiColor(hex, silent)
    if hex == nil or tostring(hex):lower() == "default" or tostring(hex) == "" then
      userConfig.UiColor = nil
      Theme.reset()
      pcall(SaveData)

      if not silent then
        notify("- UI color reset -")
      end

      return true
    end

    local color = Theme.hexToColor(hex)

    if not color then
      if not silent then
        errorNotify("- Invalid color. Use a HEX code like #3B82F6 -")
      end

      return false
    end

    if Theme.apply(color) then
      userConfig.UiColor = Theme.colorToHex(color)
      pcall(SaveData)

      if not silent then
        notify("- UI color: " .. userConfig.UiColor .. " -")
      end

      return true
    end

    if not silent then
      errorNotify("- UI color: could not find the accent color -")
    end

    return false
  end

  function GY.pickPreset(choice)
    for _, preset in ipairs(GY.PRESETS) do
      if preset[1] == choice then
        GY.setUiColor(preset[2])
        return
      end
    end
  end

  -- called once the whole UI has been built
  function GY.afterUiBuilt()
    pcall(GY.discover)

    if userConfig.UiColor then
      GY.setUiColor(userConfig.UiColor, true)

      task.delay(2, function()
        if GY.alive and userConfig.UiColor then
          pcall(Theme.scan)
          pcall(Theme.apply, Theme.hexToColor(userConfig.UiColor))
        end
      end)
    end
  end

  ---------------------------------------------------------------- biomes that are not in the table yet
  local NOT_A_BIOME = { NORMAL = true, ["THE LIMBO"] = true, ERROR = true, LOADING = true, NONE = true,
    UNKNOWN = true, DAY = true, NIGHT = true, ["N/A"] = true }

  -- returns false while a new name is only seen once (so the scanner waits one more scan),
  -- learns it on the second sighting, and true for everything else
  function GY.confirmBiome(biomes, name, normalName)
    if type(name) ~= "string" or biomes[name] then
      return true
    end

    if NOT_A_BIOME[name] or name == tostring(normalName or ""):upper() or #name < 3 or #name > 28
      or not name:match("^[A-Z][A-Z '%-]+$") then
      return true
    end

    local first = GY.seen[name]

    if not first or tick() - first > 30 then
      GY.seen[name] = tick()
      return false
    end

    GY.seen[name] = nil
    biomes[name] = { 5793266, nil, false }
    userConfig.LearnedBiomes = userConfig.LearnedBiomes or {}
    userConfig.LearnedBiomes[name] = true

    if not pcall(SaveDataDebounced) then
      pcall(SaveData)
    end

    notify("- New biome learned: " .. name .. " -", Color3.fromRGB(120, 200, 255))
    return true
  end

  function GY.restoreLearnedBiomes(biomes)
    if type(userConfig) == "table" and type(userConfig.LearnedBiomes) == "table" then
      for name in pairs(userConfig.LearnedBiomes) do
        if not biomes[name] then
          biomes[name] = { 5793266, nil, false }
        end
      end
    end
  end

  -- the HUD scan walks the whole interface; ask it at most every 0.3 s
  function GY.memoBiome(rawFn)
    local lastAt, lastValue = -1, nil

    return function()
      local now = tick()

      if now - lastAt < 0.3 then
        return lastValue
      end

      lastValue = rawFn()
      lastAt = now
      return lastValue
    end
  end

  -- different libraries name the list-refresh call differently: try the usual names
  function GY.refreshList(handle, items)
    if type(handle) ~= "table" then
      return
    end

    for _, name in ipairs({ "SetItems", "SetList", "Refresh", "Update", "Set" }) do
      if type(handle[name]) == "function" then
        if pcall(handle[name], handle, items) then
          return
        end
      end
    end
  end

  ---------------------------------------------------------------- hooking everything into the UI window
  local WRAP_METHODS = {
    "AddDivider", "AddSectionHeader", "AddLabel", "AddToggle", "AddButton", "AddInput", "AddInputNumber",
    "AddDropdown", "AddAlert", "AddMetricRow", "AddStatusBadge", "AddStatusBadge2", "AddList", "AddActionList",
    "AddMultiSelect", "AddLogConsole", "AddButtonRow", "SetMetricValue",
  }

  function GY.attachUi(window)
    for _, method in ipairs(WRAP_METHODS) do
      local original = window[method]

      if type(original) == "function" then
        local skipTables = method == "AddDropdown" or method == "AddMultiSelect" or method == "AddList"

        window[method] = function(self, ...)
          local args = table.pack(...)

          for i = 1, args.n do
            local value = args[i]

            if type(value) == "string" then
              args[i] = GY.T(value)
            elseif type(value) == "table" and not skipTables then
              translateFields(value, 1)
            end
          end

          return original(self, table.unpack(args, 1, args.n))
        end
      end
    end

    pcall(function() window:OnDestroy(function() GY.destroy() end) end)

    if not GY.noticeWrapped then
      GY.noticeWrapped = true
      local rawNotify, rawError = notify, errorNotify

      if type(rawNotify) == "function" then
        notify = function(text, ...) return rawNotify(GY.translateNotice(text), ...) end
      end

      if type(rawError) == "function" then
        errorNotify = function(text, ...) return rawError(GY.translateNotice(text), ...) end
      end
    end

    GY.startDiscovery()
  end

  ---------------------------------------------------------------- faster walking
  local function pointToSegment(point, a, b)
    local ab = b - a
    local len2 = ab:Dot(ab)

    if len2 < 1e-6 then
      return (point - a).Magnitude
    end

    local t = math.clamp((point - a):Dot(ab) / len2, 0, 1)
    return (point - (a + ab * t)).Magnitude
  end

  -- drops waypoints that lie on a straight line (same route, fewer stops). Jumps are always kept.
  function GY.simplify(waypoints)
    if type(waypoints) ~= "table" or (type(userConfig) == "table" and userConfig.FastWalk == false) then
      return waypoints
    end

    local count = #waypoints

    if count < 3 then
      return waypoints
    end

    local walk = Enum.PathWaypointAction.Walk
    local result = { waypoints[1] }
    local anchor = 1

    while anchor < count do
      local reach = anchor + 1

      for candidate = anchor + 2, count do
        local ok = true

        for middle = anchor + 1, candidate - 1 do
          local mid = waypoints[middle]

          if mid.Action ~= walk
            or pointToSegment(mid.Position, waypoints[anchor].Position, waypoints[candidate].Position) > 0.6 then
            ok = false
            break
          end
        end

        if not ok then
          break
        end

        reach = candidate
      end

      result[#result + 1] = waypoints[reach]
      anchor = reach
    end

    return result
  end

  ---------------------------------------------------------------- FPS boost
  local FX_CLASSES = { "ParticleEmitter", "Trail", "Beam", "Fire", "Smoke", "Sparkles" }

  local function isFx(obj)
    for _, className in ipairs(FX_CLASSES) do
      if obj:IsA(className) then
        return true
      end
    end

    return false
  end

  function GY.setFpsBoost(on)
    local lighting = game:GetService("Lighting")

    if on then
      GY.fpsOn = true
      GY.saved = GY.saved or {}
      GY.fxOff = GY.fxOff or {}

      pcall(function()
        if GY.saved.quality == nil then
          GY.saved.quality = settings().Rendering.QualityLevel
        end

        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
      end)

      pcall(function()
        if GY.saved.shadows == nil then
          GY.saved.shadows = lighting.GlobalShadows
        end

        lighting.GlobalShadows = false
      end)

      local function silence(obj)
        if isFx(obj) and obj.Enabled and not GY.fxOff[obj] then
          GY.fxOff[obj] = true
          obj.Enabled = false
        end
      end

      task.spawn(function()
        local n = 0

        for _, obj in ipairs(workspace:GetDescendants()) do
          if not GY.fpsOn then
            return
          end

          pcall(silence, obj)
          n = n + 1

          if n % 400 == 0 then
            task.wait()
          end
        end
      end)

      if not GY.fxConn then
        GY.fxConn = workspace.DescendantAdded:Connect(function(obj)
          if GY.fpsOn then
            pcall(silence, obj)
          end
        end)
      end
    else
      GY.fpsOn = false

      pcall(function()
        if GY.saved and GY.saved.quality ~= nil then
          settings().Rendering.QualityLevel = GY.saved.quality
        end
      end)

      pcall(function()
        if GY.saved and GY.saved.shadows ~= nil then
          lighting.GlobalShadows = GY.saved.shadows
        end
      end)

      for obj in pairs(GY.fxOff or {}) do
        pcall(function()
          if obj.Parent then
            obj.Enabled = true
          end
        end)
      end

      GY.fxOff = {}
      GY.saved = {}

      if GY.fxConn then
        GY.fxConn:Disconnect()
        GY.fxConn = nil
      end
    end
  end

  ---------------------------------------------------------------- cleanup
  function GY.destroy()
    if not GY.alive then
      return
    end

    GY.alive = false

    if GY.fpsOn then
      pcall(GY.setFpsBoost, false)
    end

    for _, entry in ipairs(Theme.entries) do
      if entry.conn then
        pcall(function() entry.conn:Disconnect() end)
      end
    end

    Theme.entries = {}

    for _, connection in ipairs(GY.conns) do
      pcall(function() connection:Disconnect() end)
    end

    GY.conns = {}
  end
end


if game.PlaceId ~= 15532962292 then
  _G.__BIOME_SCRIPT_LOADING = false
  errorNotify("- Error: Script only works on Sols RNG -")
  return
else
  configFilePath = "BiomeMacroConfigs" .. "/" .. "Config_" .. localPlayer.Name .. ".json"

  userConfig = {
    PSLink = "",
    Webhook = "",
    DiscordId = "",
    RoleId = "",
    PingThreshold = 999999999,
    AntiAfk = true,
    BiomeScanInterval = 0.5,
    AntiAfkInterval = 300,
    AutoFishTarget = 20,
    AutoFishSCBRMins = 5,
    AutoSellActive = false,
    AutoFishingActive = false,
    SCBRActive = false,
    AutoObbyLuckBoost = false,
    AutoCollectClover = false,
    AutoContractWithEden = false,
    AutoMerchant = { Enabled = false, Rules = {} },
    AutomationPriority = true,
    PathDebug = false,
    FastWalk = true,
    FpsBoost = false,
    Language = "en",
    AutoExecute = false,
    WasMacroRunning = false,
    MutedBiomes = {},
    PingBiomes = {},
    PingMerchants = {},
    PingEden = true,
    CustomPingIds = {},
    Username = "",
    LastSeenUpdateLogVersion = "",
    AutoResetOnRareBiome = false,
    AutoPop = { Enabled = false, Rules = {} },
  }

  globalStats = { TotalBiomes = 0, BiomeDetails = {}, BiomeLastSeen = {} }
  v12 = { BiomeCount = 0, MerchantCount = 0, StartTick = 0 }
  name = nil
  v13 = nil
  macroRunning = false
  v15 = false
  v16 = nil
  v17 = nil
  v18 = false
  v19 = false
  v20 = {}
  v21 = {}
  v22 = {}
  v23 = false
  v24 = nil

  function configureWaterAsVoid()
    local count = 0

    local function f8()
      count = count + 1

      if count % 50 == 0 then
        task.wait()
      end
    end

    local v90 = workspace
    local v91 = {}
    local v92 = workspace

    for index4, value4 in ipairs({ v90:FindFirstChild("Map"), v92:FindFirstChild("Terrain") }) do
      if value4 then
        for index5, value5 in ipairs({ "Miscs", "Water", "WaterBlocks", "WaterFolder" }) do
          local findFirstChild = value4:FindFirstChild(value5)

          if findFirstChild then
            v91[findFirstChild] = true
          end
        end
      end
    end

    for index6, value6 in ipairs(workspace:GetDescendants()) do
      if value6:IsA("BasePart") then
        local v93 = false
        local parent2 = value6.Parent

        while parent2 and parent2 ~= workspace do
          if v91[parent2] then
            v93 = true
            break
          end

          parent2 = parent2.Parent
        end

        if (v93 or value6.Name:lower():find("water"))
          and not value6:FindFirstChild("WaterVoidModifier") then
          local waterVoidModifier = Instance.new("PathfindingModifier")
          waterVoidModifier.Name = "WaterVoidModifier"
          waterVoidModifier.Label = "WaterVoid"
          waterVoidModifier.PassThrough = false
          waterVoidModifier.Parent = value6
        end

        f8()
      end
    end
  end

  function startWaterConfigLoop()
    if v23 then
      return
    end

    v23 = true
    v24 = task.spawn(function() configureWaterAsVoid() end)
  end

  function stopWaterConfigLoop()
    v23 = false

    if v24 then
      pcall(function() task.cancel(v24) end)
      v24 = nil
    end
  end

  function resetWaterConfigState()
    stopWaterConfigLoop()
    v23 = false
    v24 = nil
  end

  _G.__BIOME_SUSPENDED = false
  _G.__BIOME_SUSPENDED_REASON = nil
  _G.__BIOME_REMOVED = false
  _G.__BIOME_REMOVED_REASON = nil

  v25 = {}
  v26 = false
  v27 = {}
  v28 = nil
  v29 = false

  function applyDashboardControlFields(p3)
    if type(p3) ~= "table" then
      return
    end

    if p3.removed == true and not _G.__BIOME_REMOVED then
      _G.__BIOME_REMOVED = true

      local g = _G
      g.__BIOME_REMOVED_REASON = tostring(p3.removed_reason or "Removed from the script")

      notify(
        "- Data sync disabled (removed) — script works locally only -",
        Color3.fromRGB(148, 163, 184)
      )
    end

    if p3.suspended == true and not _G.__BIOME_SUSPENDED then
      _G.__BIOME_SUSPENDED = true
      local g2 = _G
      g2.__BIOME_SUSPENDED_REASON = tostring(p3.suspended_reason or "No reason provided")
    end

    if p3.kick == true and not v29 then
      v29 = true
      v25 = {}
      task.delay(0.5, function() pcall(function() players.LocalPlayer:Kick("") end) end)
    end
  end

  function processDashboardQueue()
    if v26 then
      return
    end

    v26 = true

    if _G.__BIOME_REMOVED then
      v25 = {}
      v26 = false
      return
    end

    local v94 = syn and syn.request or request or http_request

    if not v94 then
      v26 = false
      return
    end

    while #v25 > 0 do
      local v95 = table.remove(v25, 1)
      local v96 = false
      local v97 = "Unknown"

      for i = 1, 3 do
        local v98, v99 = pcall(function()
          return v94({
            Url = "https://slaoq-worker.gustaslaoq.workers.dev" .. v95.endpoint,
            Method = "POST",
            Headers = {
              ["Content-Type"] = "application/json",
              ["X-Webhook-Secret"] = "slaoq-dash-wk-secret-2024-abc-def-8472",
            },
            Body = httpService:JSONEncode(v95.payload),
          })
        end)

        if v98 and v99 then
          local statusCode = v99.StatusCode or v99.statusCode or 0
          local body = v99.Body or v99.body or ""

          if statusCode == 200 or statusCode == 201 then
            v96 = true
            local v100, v101 = pcall(function() return httpService:JSONDecode(body) end)

            if v100 then
              applyDashboardControlFields(v101)
            end

            break
          elseif statusCode == 403 then
            local v102, v103 = pcall(function() return httpService:JSONDecode(body) end)

            if v102 and type(v103) == "table" then
              if v103.error == "suspended" then
                _G.__BIOME_SUSPENDED = true
                local g3 = _G

                g3.__BIOME_SUSPENDED_REASON = v103.suspended_reason or v103.reason
                  or "No reason provided"
              elseif v103.error == "removed" then
                _G.__BIOME_REMOVED = true
                local g4 = _G

                g4.__BIOME_REMOVED_REASON = v103.removed_reason or v103.reason
                  or "No reason provided"
              end

              applyDashboardControlFields(v103)
            end

            break
          elseif statusCode == 429 then
            v97 = "Rate Limited"
            task.wait(2)
          elseif statusCode >= 500 then
            v97 = "Server Error (" .. statusCode .. ")"
            task.wait(i * 1)
          else
            v97 = "HTTP " .. statusCode
            break
          end
        else
          v97 = "Request failed"
          task.wait(i * 1)
        end
      end

      if not v96 and v97 ~= "SUSPENDED" and v97 ~= "Rate Limited" then
        warn("[Dashboard] Failed: " .. (v95.endpoint or "?") .. " - " .. v97)
      end

      if _G.__BIOME_REMOVED then
        v25 = {}
      end
    end

    v26 = false
  end

  function enqueueDashboardEvent(endpoint, payload)
    if _G.__BIOME_REMOVED then
      return
    end

    if #v25 >= 50 then
      table.remove(v25, 1)
    end

    table.insert(v25, { endpoint = endpoint, payload = payload })
    task.spawn(processDashboardQueue)
  end

  function flushBiomeBatch()
    if #v27 == 0 then
      return
    else
      local v104 = v27
      v27 = {}
      v28 = nil
      local v105 = v104[1]

      enqueueDashboardEvent("/webhook/biome-batch", {
        sessionId = v105.sessionId,
        userId = v105.userId,
        username = v105.username,
        biomes = v104,
      })

      return
    end
  end

  function enqueueBiomeFound(p4)
    table.insert(v27, {
      biomeName = p4.biomeName,
      colorHex = p4.colorHex,
      imageUrl = p4.imageUrl,
      isRare = p4.isRare,
      timestamp = p4.timestamp,
      sessionId = p4.sessionId,
      userId = p4.userId,
      username = p4.username,
    })

    if #v27 >= 10 then
      flushBiomeBatch()
    elseif not v28 then
      v28 = task.delay(30, flushBiomeBatch)
    end
  end

  v30 = {}
  v31 = nil

  function flushMerchantBatch()
    if #v30 == 0 then
      return
    else
      local v106 = v30
      v30 = {}
      v31 = nil
      local v107 = v106[1]

      enqueueDashboardEvent("/webhook/merchant-batch", {
        sessionId = v107.sessionId,
        userId = v107.userId,
        username = v107.username,
        merchants = v106,
      })

      return
    end
  end

  function enqueueMerchantFound(p5)
    table.insert(v30, {
      merchantName = p5.merchantName,
      timestamp = p5.timestamp,
      sessionId = p5.sessionId,
      userId = p5.userId,
      username = p5.username,
    })

    if #v30 >= 3 then
      flushMerchantBatch()
    elseif not v31 then
      v31 = task.delay(30, flushMerchantBatch)
    end
  end

  function CleanupMacro()
    resetWaterConfigState()
    v19 = false

    for index7, value7 in ipairs(v22) do
    end

    for index8, value8 in ipairs(v20) do
    end

    v20 = {}

    for index9, value9 in ipairs(v21) do
      local v108 = value9

      if v108 then
        pcall(function() task.cancel(v108) end)
      end
    end

    v21 = {}

    if v28 then
      pcall(function() task.cancel(v28) end)
      v28 = nil
    end

    if #v27 > 0 then
      local v109 = v27
      v27 = {}
      local v110 = v109[1]

      enqueueDashboardEvent("/webhook/biome-batch", {
        sessionId = v110.sessionId,
        userId = v110.userId,
        username = v110.username,
        biomes = v109,
      })
    end

    if v31 then
      pcall(function() task.cancel(v31) end)
      v31 = nil
    end

    if #v30 > 0 then
      local v111 = v30
      v30 = {}
      local v112 = v111[1]

      enqueueDashboardEvent("/webhook/merchant-batch", {
        sessionId = v112.sessionId,
        userId = v112.userId,
        username = v112.username,
        merchants = v111,
      })
    end
  end

  function formatElapsed(p6)
    local v113 = math.floor(p6)

    if v113 < 0 then
      v113 = 0
    end

    local v114 = math.floor(v113 / 86400)
    local v115 = math.floor(v113 % 86400 / 3600)
    local v116 = math.floor(v113 % 3600 / 60)
    local v117 = v113 % 60
    local v118 = {}

    if v114 > 0 then
      table.insert(v118, v114 .. "d")
    end

    if v115 > 0 then
      table.insert(v118, v115 .. "h")
    end

    if v116 > 0 then
      table.insert(v118, v116 .. "m")
    end

    if #v118 == 0 then
      table.insert(v118, v117 .. "s")
    elseif v114 == 0 and v115 == 0 then
      table.insert(v118, v117 .. "s")
    end

    return table.concat(v118, " ")
  end

  function SaveData()
    local v119

    if writefile then
      userConfig.Username = localPlayer.Name
      local v120 = {}

      for key, value10 in pairs(userConfig) do
        v120[key] = value10
      end

      v120.AutoObbyLuckBoost = false
      v120.AutoCollectClover = false

      local globalStats2 = globalStats
      local name2 = name
      local v121 = v13
      v119 = configFilePath .. ".tmp"

      local jsonEncode = httpService:JSONEncode({
        Config = v120,
        GlobalStats = globalStats2,
        LastBiomeInfo = { Name = name2, Time = v121 },
      })

      local v122, v123 = pcall(function() writefile(v119, jsonEncode) end)

      if not v122 then
        warn("Error writing temp config file: " .. tostring(v123))
        return
      else
        local v124 = rename or movefile or type(os) == "table" and os.rename
        local v125 = false

        if v124 then
          v125 = pcall(function() v124(v119, configFilePath) end) and isfile and isfile(configFilePath)
        end

        if not v125 then
          local v126, v127 = pcall(function() writefile(configFilePath, jsonEncode) end)

          if not v126 then
            warn("Error writing to final path: " .. tostring(v127))
            return
          end
        end

        if delfile and isfile and isfile(configFilePath) then
          if pcall(function() return httpService:JSONDecode(readfile(configFilePath)) ~= nil end) then
            pcall(function() delfile(v119) end)
          end
        end

        return
      end
    else
      return
    end
  end

  v32 = false

  function SaveDataDebounced()
    if v32 then
      return
    end

    v32 = true

    task.delay(5, function()
      SaveData()
      v32 = false
    end)
  end

  function LoadData()
    local v128 = readfile and isfolder and makefolder and isfile
    local v129

    if v128 then
      if not isfolder("BiomeMacroConfigs") then
        makefolder("BiomeMacroConfigs")
      end

      v129 = configFilePath .. ".tmp"
      local v130 = nil

      if isfile(configFilePath) then
        local v131, v132 = pcall(function() return httpService:JSONDecode(readfile(configFilePath)) end)

        if v131 and type(v132) == "table" then
          v130 = v132
        end
      end

      if not v130 and isfile(v129) then
        local v133, v134 = pcall(function() return httpService:JSONDecode(readfile(v129)) end)

        if v133 and type(v134) == "table" then
          v130 = v134
          warn("[Biome Script] Config principal ausente/corrompida — recuperado a partir do backup .tmp")
        end
      end

      if v130 ~= nil and type(v130) == "table" then
        if v130.Config and type(v130.Config) == "table" then
          for key2, value11 in pairs(v130.Config) do
            userConfig[key2] = value11
          end

          if not userConfig.PingBiomes then
            userConfig.PingBiomes = {}
          end

          if not userConfig.PingMerchants then
            userConfig.PingMerchants = {}
          end

          if userConfig.PingEden == nil then
            userConfig.PingEden = true
          end

          if not userConfig.RoleId then
            userConfig.RoleId = ""
          end

          if not userConfig.MutedBiomes then
            userConfig.MutedBiomes = {}
          end

          if not userConfig.CustomPingIds then
            userConfig.CustomPingIds = {}
          end

          if not userConfig.BiomeScanInterval then
            userConfig.BiomeScanInterval = 0.5
          end

          if not userConfig.AntiAfkInterval then
            userConfig.AntiAfkInterval = 300
          end

          if not userConfig.AutoFishTarget then
            userConfig.AutoFishTarget = 20
          end

          if not userConfig.AutoFishSCBRMins then
            userConfig.AutoFishSCBRMins = 5
          end

          if userConfig.AutoSellActive == nil then
            userConfig.AutoSellActive = false
          end

          if userConfig.AutoFishingActive == nil then
            userConfig.AutoFishingActive = false
          end

          if userConfig.SCBRActive == nil then
            userConfig.SCBRActive = false
          end

          if userConfig.AutoObbyLuckBoost == nil then
            userConfig.AutoObbyLuckBoost = false
          end

          if userConfig.AutoCollectClover == nil then
            userConfig.AutoCollectClover = false
          end

          if userConfig.AutoContractWithEden == nil then
            userConfig.AutoContractWithEden = false
          end

          if type(userConfig.AutoMerchant) ~= "table" then
            userConfig.AutoMerchant = { Enabled = false, Rules = {} }
          end

          if userConfig.AutoMerchant.Enabled == nil then
            userConfig.AutoMerchant.Enabled = false
          end

          if not userConfig.AutoMerchant.Rules then
            userConfig.AutoMerchant.Rules = {}
          end

          if userConfig.AutomationPriority == nil then
            userConfig.AutomationPriority = true
          end

          if userConfig.PathDebug == nil then
            userConfig.PathDebug = false
          end

          if userConfig.AutoExecute == nil then
            userConfig.AutoExecute = false
          end

          if userConfig.WasMacroRunning == nil then
            userConfig.WasMacroRunning = false
          end

          if userConfig.LastSeenUpdateLogVersion == nil then
            userConfig.LastSeenUpdateLogVersion = ""
          end

          if userConfig.AutoResetOnRareBiome == nil then
            userConfig.AutoResetOnRareBiome = false
          end

          if not userConfig.AutoPop then
            userConfig.AutoPop = { Enabled = false, Rules = {} }
          end

          if userConfig.AutoPop.Enabled == nil then
            userConfig.AutoPop.Enabled = false
          end

          if not userConfig.AutoPop.Rules then
            userConfig.AutoPop.Rules = {}
          end
        end

        if v130.GlobalStats and type(v130.GlobalStats) == "table" then
          globalStats = v130.GlobalStats

          if not globalStats.BiomeDetails then
            globalStats.BiomeDetails = {}
          end

          if not globalStats.TotalBiomes then
            globalStats.TotalBiomes = 0
          end

          if not globalStats.BiomeLastSeen then
            globalStats.BiomeLastSeen = {}
          end
        end

        if v130.LastBiomeInfo and type(v130.LastBiomeInfo) == "table" then
          name = v130.LastBiomeInfo.Name
          v13 = v130.LastBiomeInfo.Time
        end
      end
    end
  end

  function QueueAutoExecute()
    local queueOnTeleport = queue_on_teleport or syn and syn.queue_on_teleport

    if not queueOnTeleport then
      print("[Biome Script] Auto Execute unavailable: queue_on_teleport missing")
      return false
    else
      local v135, v136 = pcall(function()
        queueOnTeleport([[
    local isfile = isfile or (syn and syn.isfile)
    local readfile = readfile or (syn and syn.readfile)
    local localFile = nil

    for _, name in ipairs({"BiomeScript.lua", "Biome Script.lua", "MacroSols.lua"}) do
        if isfile and isfile(name) then
            localFile = name
            break
        end
    end

    if localFile then
        loadstring(readfile(localFile))()
    else
        loadstring(game:HttpGet("https://raw.githubusercontent.com/gustaslaoq/MobileMacro/refs/heads/main/android.lua", true))()
    end
]])
      end)

      if v135 then
        print("[Biome Script] Auto Execute queued for next teleport")
        return true
      end

      print("[Biome Script] Auto Execute queue failed: " .. tostring(v136))
      return false
    end
  end

  LoadData()

  if userConfig.AutoExecute then
    QueueAutoExecute()
  end

  userConfig.AutoObbyLuckBoost = false
  userConfig.AutoCollectClover = false

  v33 = nil
  v34 = false
  v35 = nil
  v36 = nil
  v37 = nil
  v38 = nil

  players.PlayerRemoving:Connect(function(player)
    if player == localPlayer then
      if macroRunning and v33 then
        pcall(v33)
      end
    end
  end)

  v39 = "v4.0"

  v40 = {
    RAINY = {
      255, "https://github.com/gustaslaoq/MobileMacro/blob/main/images/Rainy.png?raw=true",
      false,
    },
    SNOWY = {
      8900346, "https://github.com/gustaslaoq/MobileMacro/blob/main/images/Snowy.png?raw=true",
      false,
    },
    ["SAND STORM"] = {
      13789470,
      "https://github.com/gustaslaoq/MobileMacro/blob/main/images/Sand%20Storm.png?raw=true",
      false,
    },
    WINDY = {
      65535, "https://github.com/gustaslaoq/MobileMacro/blob/main/images/Windy.png?raw=true",
      false,
    },
    STARFALL = {
      10040012,
      "https://github.com/gustaslaoq/MobileMacro/blob/main/images/Starfall.png?raw=true", false,
    },
    HELL = {
      16711680, "https://github.com/gustaslaoq/MobileMacro/blob/main/images/Hell.png?raw=true",
      false,
    },
    DREAMSPACE = {
      16738740,
      "https://github.com/gustaslaoq/MobileMacro/blob/main/images/Dreamspace.png?raw=true",
      true,
    },
    GLITCHED = {
      65280, "https://github.com/gustaslaoq/MobileMacro/blob/main/images/Glitched.png?raw=true",
      true,
    },
    HEAVEN = {
      16777215,
      "https://github.com/gustaslaoq/MobileMacro/blob/main/images/Heaven.png?raw=true", false,
    },
    NULL = {
      0, "https://github.com/gustaslaoq/MobileMacro/blob/main/images/Null.png?raw=true", false,
    },
    CYBERSPACE = {
      65514,
      "https://github.com/gustaslaoq/MobileMacro/blob/main/images/Cyberspace.jpg?raw=true",
      true,
    },
    AURORA = {
      8388564, "https://github.com/gustaslaoq/MobileMacro/blob/main/images/Aurora.png?raw=true",
      false,
    },
    CORRUPTION = {
      7995596,
      "https://github.com/gustaslaoq/MobileMacro/blob/main/images/Corruption.png?raw=true",
      false,
    },
    SINGULARITY = {
      15237644,
      "https://raw.githubusercontent.com/vexsyx/OysterDetector/refs/heads/main/assets/singularity.png",
      false,
    },
    ["LOST FOREST"] = { 3050327, nil, false },
    ["THE RADIANT FOREST"] = { 13172570, nil, false },
  }

  GYESG.restoreLearnedBiomes(v40)

  v41 = { "DREAMSPACE", "GLITCHED", "CYBERSPACE" }
  v42 = { "Mari", "Jester", "Rin" }
  local v137 = { "AURORA" }

  local g5 = _G
  g5.__AM = _G.__AM or {}

  _G.__AM.ItemOptions = {
    Mari = {
      "Lucky Potion", "Lucky Potion L", "Lucky Potion XL", "Speed Potion", "Speed Potion L",
      "Speed Potion XL", "Mixed Potion", "Fortune Spoid I", "Fortune Spoid II",
      "Fortune Spoid III", "Gear A", "Gear B", "Lucky Penny", "Void Coin",
    },
    Jester = {
      "Lucky Potion", "Speed Potion", "Random Potion Sack", "Stella's Star", "Rune of Wind",
      "Rune of Frost", "Rune of Rainstorm", "Rune of Hell", "Rune of Galaxy",
      "Rune of Corruption", "Rune of Nothing", "Rune of Everything", "Strange Potion I",
      "Strange Potion II", "Stella's Candle", "Oblivion Potion", "Potion of Bound",
      "Merchant Tracker", "Heavenly Potion",
    },
    Rin = {
      "Sunstone Talisman", "Moonstone Talisman", "Day and Night Talisman", "Overtime Talisman",
      "Soul Collector's Talisman", "Soul Master's Talisman",
    },
  }

  v43 = {}

  for index10, value12 in ipairs(v137) do
    v43[value12] = true
  end

  function isBiomeInactive(key3)
    return v43[key3] == true
  end

  function smartShorten(p7)
    if not p7 then
      return ""
    end

    if #p7 > 40 then
      return string.sub(p7, 1, 23) .. " ... " .. string.sub(p7, -12)
    end

    return p7
  end

  function extractWebhooks(p8)
    local v138 = {}

    if type(p8) == "string" then
      for match in p8:gmatch("https://discord%.com/api/webhooks/%S+") do
        v138[#v138 + 1] = match
      end
    end

    return v138
  end

  function hasValidWebhook()
    return #extractWebhooks(userConfig.Webhook) > 0
  end

  function ensureAutoMerchantConfig()
    if type(userConfig.AutoMerchant) ~= "table" then
      userConfig.AutoMerchant = { Enabled = false, Rules = {} }
    end

    if userConfig.AutoMerchant.Enabled == nil then
      userConfig.AutoMerchant.Enabled = false
    end

    if type(userConfig.AutoMerchant.Rules) ~= "table" then
      userConfig.AutoMerchant.Rules = {}
    end

    return userConfig.AutoMerchant
  end

  function isMerchantGuidName(p9)
    return type(p9) == "string"
      and p9:match("^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$")
        ~= nil
  end

  function detectMerchantTypeFromModel(p10)
    if not p10 or not p10:IsA("Model") or not isMerchantGuidName(p10.Name) then
      return nil
    end

    for index11, value13 in ipairs(p10:GetDescendants()) do
      local name3 = value13.Name

      if name3 == "Mari's Backpack" then
        return "Mari"
      elseif name3 == "Jester's Mask" then
        return "Jester"
      elseif name3 == "someitem" and value13:IsA("Model") then
        return "Rin"
      end
    end

    return nil
  end

  function getModelPosition(p11)
    if not p11 or not p11.Parent then
      return nil
    else
      local v139, v140 = pcall(function() return p11:GetPivot() end)

      if v139 and v140 then
        return v140.Position
      else
        local findFirstChildWhichIsA = p11:FindFirstChildWhichIsA("BasePart", true)
        return findFirstChildWhichIsA and findFirstChildWhichIsA.Position or nil
      end
    end
  end

  function scanMerchantModels()
    local v141 = {}
    local map = workspace:FindFirstChild("Map")

    if not map then
      return v141
    end

    for index12, value14 in ipairs(map:GetChildren()) do
      local v142 = detectMerchantTypeFromModel(value14)

      if v142 then
        local v143 = getModelPosition(value14)

        if v143 then
          v141[#v141 + 1] = { Name = v142, Model = value14, Position = v143 }
        end
      end
    end

    return v141
  end

  function parseDiscordIds(p12)
    local v144 = {}

    if type(p12) == "string" then
      for match2 in p12:gmatch("%d+") do
        v144[#v144 + 1] = match2
      end
    end

    return v144
  end

  function setDiscordId(key4, p13)
    local v145 = parseDiscordIds(userConfig.DiscordId)

    while #v145 < key4 do
      table.insert(v145, "")
    end

    v145[key4] = p13

    while #v145 > 0 and v145[#v145] == "" do
      table.remove(v145)
    end

    userConfig.DiscordId = table.concat(v145, ", ")
  end

  function parseCustomPingIds(p14)
    local v146 = {}
    local v147 = {}

    if type(p14) == "string" and p14 ~= "" then
      for match3 in p14:gmatch("[^,]+") do
        local sS = match3:match("^%s*(.-)%s*$")

        if sS:match("^r:%s*%d+$") then
          v147[#v147 + 1] = sS:gsub("^r:%s*", "")
        elseif sS:match("^%d+$") then
          v146[#v146 + 1] = sS
        end
      end
    end

    return v146, v147
  end

  httpRequest = syn and syn.request or request or http_request

  if httpRequest then
    local reason = nil

    for j = 1, 4 do
      local v148, v149 = pcall(function()
        return httpRequest({
          Url = "https://slaoq-worker.gustaslaoq.workers.dev/webhook/script-executed",
          Method = "POST",
          Headers = {
            ["Content-Type"] = "application/json",
            ["X-Webhook-Secret"] = "slaoq-dash-wk-secret-2024-abc-def-8472",
          },
          Body = httpService:JSONEncode({
            userId = tostring(localPlayer.UserId),
            username = localPlayer.Name,
            executor = identifyexecutor and identifyexecutor()
              or syn and syn.crypto and "Synapse X" or nil,
          }),
        })
      end)

      if v148 and v149 then
        local statusCode2 = v149.StatusCode or v149.statusCode or 0

        if statusCode2 == 200 or statusCode2 == 201 then
          break
        end

        if statusCode2 == 403 then
          local v150, v151 = pcall(function()
            return httpService:JSONDecode(v149.Body or v149.body or "{}")
          end)

          if v150 and v151 and v151.error == "suspended" then
            reason = v151.reason or ""
          elseif v150 and v151 and v151.error == "removed" then
            _G.__BIOME_REMOVED = true
            local g6 = _G
            g6.__BIOME_REMOVED_REASON = v151.reason or "No reason provided"
          end

          break
        end

        warn("[Dashboard] script-executed attempt " .. j .. "/4: HTTP " .. statusCode2 .. " | "
          .. (v149.Body or v149.body or ""):sub(1, 200))

        task.wait(j * 1.5)
      else
        warn("[Dashboard] script-executed attempt " .. j .. "/4: "
          .. tostring(v149 or "no response"))

        task.wait(j * 1.5)
      end
    end

    if reason ~= nil then
      local v152 = reason ~= "" and " Reason: " .. reason or ""

      _G.__BIOME_SCRIPT_LOADING = false
      _G.__BIOME_SCRIPT_EXECUTED = false

      errorNotify("- Error: Your account is suspended from using this script!" .. v152 .. " -")
      warn("[Dashboard] Script execution rejected — account suspended." .. v152)
      error("Account suspended")
    elseif _G.__BIOME_REMOVED then
      notify("- Data sync disabled"
        .. (_G.__BIOME_REMOVED_REASON and _G.__BIOME_REMOVED_REASON ~= ""
            and " (" .. _G.__BIOME_REMOVED_REASON .. ")"
          or "")
        .. " — script works locally only -", Color3.fromRGB(148, 163, 184))

      warn("[Dashboard] Script execution allowed — account removed, data sync disabled.")
    end
  end

  uiLibrary = nil

  local v153, v154 = pcall(function()
    local httpGet

    local v155, v156 = pcall(function()
      httpGet = game:HttpGet("https://raw.githubusercontent.com/gustaslaoq/MobileMacro/refs/heads/main/biomescript_uilibrary.lua?t="
        .. tostring(os.time()), true)
    end)

    if not (v155 and type(httpGet) == "string" and httpGet ~= "") then
      if readfile and isfile and isfile("biomescript_uilibrary.lua") then
        httpGet = readfile("biomescript_uilibrary.lua")
      else
        error(v156 or "UI source unavailable")
      end
    end

    uiLibrary = loadstring(httpGet)()
  end)

  if not v153 then
    _G.__BIOME_SCRIPT_LOADING = false
    errorNotify("- Error: Failed to load UI library -")
    warn("UI library load failed: " .. tostring(v154))
    return
  else
    v46 = {
      {
        Version = v39,
        Lines = {
          {
            Text = "Biome Script v4.0 release",
            Bold = true,
            Color = Color3.fromRGB(255, 255, 255),
          },
          {
            Text = "Biomes: added LOST FOREST and THE RADIANT FOREST (Radiant Forest update) +",
            Color = Color3.fromRGB(120, 255, 150),
          },
          {
            Text = "Biomes: unknown biome names are now learned automatically, so future biome updates are detected +",
            Color = Color3.fromRGB(120, 255, 150),
          },
          {
            Text = "UI: new UI COLOR option in Settings (preset colors or any HEX code) +",
            Color = Color3.fromRGB(120, 255, 150),
          },
          {
            Text = "Language: Thai / English interface in Settings +",
            Color = Color3.fromRGB(120, 255, 150),
          },
          {
            Text = "Walking: fewer path searches and straighter routes (Fast Walk) /",
            Color = Color3.fromRGB(255, 215, 95),
          },
          {
            Text = "Performance: faster start-up and a lighter biome HUD scan /",
            Color = Color3.fromRGB(255, 215, 95),
          },
          {
            Text = "Settings: FPS Boost option +",
            Color = Color3.fromRGB(120, 255, 150),
          },
          {
            Text = "Fixed: two broken goto spots from the old build /",
            Color = Color3.fromRGB(255, 215, 95),
          },
        },
      },
      {
        Version = "v3.8",
        Lines = {
          {
            Text = "Biome Script v3.8 release",
            Bold = true,
            Color = Color3.fromRGB(255, 255, 255),
          },
          {
            Text = "UI: added the new update log screen, boot splash, and player card +",
            Color = Color3.fromRGB(120, 255, 150),
          },
          {
            Text = "UI: changed mobile sizing and the general Monolith interface style /",
            Color = Color3.fromRGB(255, 215, 95),
          },
          {
            Text = "Main: changed webhook management with a saved webhook list, per-webhook test/delete, and a 10 webhook limit /",
            Color = Color3.fromRGB(255, 215, 95),
          },
          {
            Text = "Automation: added Auto Pop rules for biome-specific item usage with custom item amounts +",
            Color = Color3.fromRGB(120, 255, 150),
          },
          {
            Text = "Automation: added Auto Merchant rules for Mari, Jester, and Rin purchases with quantity and Set to Max support +",
            Color = Color3.fromRGB(120, 255, 150),
          },
          {
            Text = "Automation: added Auto Collect Clover as an extra world collection system +",
            Color = Color3.fromRGB(120, 255, 150),
          },
          {
            Text = "Automation: added Auto Obby Luck Boost with assisted Obby routing...",
            Color = Color3.fromRGB(120, 255, 150),
          },
        },
      },
    }

    local v157 = userConfig.LastSeenUpdateLogVersion ~= v39

    local v158 = {
      { Name = "Main" }, { Name = "Status" }, { Name = "Automation" },
      { Name = "Biome Counts" }, { Name = "Pings" }, { Name = "Settings" },
    }

    if v2 then
      table.insert(v158, { Name = "Admin" })
    end

    table.insert(v158, { Name = "Update Log", Hidden = true })

    pcall(function() GYESG.before = GYESG.snapshotGuis() end)

    pcall(function()
      for _, page in ipairs(v158) do
        page.Name = GYESG.T(page.Name)
      end
    end)

    ui = uiLibrary.new({
      AppName = "Biome Script",
      AppSubtitle = "by GYESG • orig. Slaoq",
      AppVersion = v39:gsub("^v", ""),
      LogoImage = "rbxassetid://102126718358520",
      GuiParent = v5 == playerGui and "PlayerGui" or "CoreGui",
      WindowWidth = 900,
      WindowHeight = 560,
      SidebarWidth = 200,
      SplashMode = "boot",
      InitialPage = v157 and (v2 and 8 or 7) or 1,
      ToggleKey = "K",
      BootSteps = 9,
      SplashTasks = {
        "Creating interface shell", "Building macro controls", "Preparing automation modules",
        "Registering status panels", "Loading notification controls", "Mounting settings",
        "Integrating fishing automation", "Rendering update log", "Ready.",
      },
      Pages = v158,
    })

    pcall(function() ui:SetSidebarUserStatus(macroRunning == true) end)

    if not pcall(GYESG.attachUi, ui) then
      warn("[GYESG] could not hook the UI window")
    end

    function bootStep(p15, p16, p17)
      pcall(function() ui:SetBootStep(p15, p16, p17) end)
      task.wait(0.03)
    end

    local v159 = v2 and 7 or nil
    v48 = v2 and 8 or 7
    addStatusBadge2 = nil
    addStatusBadge22 = nil
    v49 = nil
    v50 = nil
    v51 = nil
    v52 = nil
    v53 = nil
    v54 = {}
    v55 = nil
    v56 = nil
    addInput = nil
    addInput2 = nil
    addInput3 = nil
    addInputNumber = nil
    addToggle = nil
    v57 = {}
    v58 = {}
    v59 = nil
    addLogConsole = nil
    v60 = {}
    addInputNumber2 = nil
    addInputNumber3 = nil
    addToggle2 = nil
    addToggle3 = nil
    addMultiSelect = nil
    addInputNumber4 = nil
    addInputNumber5 = nil
    bootStep("Building macro controls", 0.16, "main page")

    ui:AddSectionHeader(
      1, "Biome Macro", "Automatic biome and merchant detection for Sol's RNG"
    )

    ui:AddDivider(1, "Control")

    addStatusBadge22 = ui:AddStatusBadge2(1, "Macro State", "offline")

    local addButtonRow = ui:AddButtonRow(1, {
      {
        Text = "Start",
        Style = "primary",
        Width = 130,
        Callback = nil,
      },
      {
        Text = "Stop",
        Style = "danger",
        Width = 130,
        Callback = nil,
      },
    })

    local function f9(text2)
      local v160 = { Button = text2 }

      function v160:Set(text3)
        if text2 and text2.Parent then
          text2.Text = tostring(text3)
        end
      end

      function v160:SetEnabled(p18)
        if text2 and text2.Parent then
          text2.Active = p18 == true
          text2.BackgroundTransparency = p18 == true and 0 or 0.5
        end
      end

      return v160
    end

    v55 = f9(addButtonRow[1])
    v56 = f9(addButtonRow[2])

    task.defer(function()
      if v55 then
        v55:SetEnabled(true)
      end

      if v56 then
        v56:SetEnabled(false)
      end
    end)

    ui:AddDivider(1, "Private Server")

    addInput2 = ui:AddInput(1, "Private Server Link", "Permanent PS link (roblox.com/share?...)", function(p19)
      if userConfig.PSLink and p19 == smartShorten(userConfig.PSLink) then
        return
      end

      userConfig.PSLink = p19
      SaveData()

      if addInput2 and p19 ~= "" then
        task.delay(0.1, function() pcall(function() addInput2:Set(smartShorten(p19)) end) end)
      end
    end)

    ui:AddDivider(1, "Webhooks")

    function f1()
      return extractWebhooks(userConfig.Webhook or "")
    end

    v61 = ""
    addActionList = nil

    function f5(p20)
      userConfig.Webhook = table.concat(p20 or {}, "\n")
      SaveData()
    end

    function f6()
      if not addActionList then
        return
      end

      GYESG.refreshList(addActionList, f1())
    end

    ui:AddButtonRow(1, {
      {
        Text = "Add Webhook",
        Style = "primary",
        Width = 150,
        Callback = function()
          local get = v61

          if addInput and addInput.Get then
            get = addInput:Get()
          end

          local v161 = extractWebhooks(get or "")[1]

          if not v161 then
            errorNotify("- Invalid webhook URL -")
            return
          else
            local v162 = f1()

            if #v162 >= 10 then
              errorNotify("- Error: Maximum webhooks is 10 -")
              return
            end

            for index13, value15 in ipairs(v162) do
              if value15 == v161 then
                errorNotify("- Webhook already added -")
                return
              end
            end

            v162[#v162 + 1] = v161
            f5(v162)
            v61 = ""

            if addInput then
              pcall(function() addInput:Set("") end)
            end

            f6()
            notify("- Webhook added -", Color3.fromRGB(100, 220, 100))
            return
          end
        end,
      },
    })

    addInput = ui:AddInput(
      1, "Discord Webhook URL", "https://discord.com/api/webhooks/...",
      function(p21) v61 = p21 end
    )

    if ui.AddActionList then
      addActionList = ui:AddActionList(1, "Saved Webhooks", {
        MaxItems = 10,
        EmptyText = "No webhooks added",
      })
    else
      addActionList = ui:AddList(1, "Saved Webhooks", { MaxItems = 10 })
    end

    f6()
    ui:AddDivider(1, "Session")

    addToggle = ui:AddToggle(1, "Anti-AFK", userConfig.AntiAfk, function(antiAfk)
      userConfig.AntiAfk = antiAfk
      SaveData()
    end, "Keeps player active to prevent disconnection")

    ui:AddDivider(1, "Actions")

    ui:AddButtonRow(1, {
      {
        Text = "Stop and Rejoin",
        Style = "danger",
        Width = 170,
        Callback = function()
          if macroRunning then
            if v33 then
              pcall(v33)
              v33 = nil
              task.wait(1)
            end

            macroRunning = false
            getgenv().MacroRunning = false
            pcall(function() ui:SetSidebarUserStatus(false) end)
            CleanupMacro()
          end

          SaveData()
          notify("- Rejoining Server... -")
          task.wait(0.5)
          teleportService:Teleport(game.PlaceId, localPlayer)
        end,
      },
      {
        Text = "Unload",
        Style = "ghost",
        Width = 120,
        Callback = function()
          if v37 then
            v37()
          end
        end,
      },
    })

    bootStep("Preparing automation pathfinding", 0.3, "path module")

    autoWalk = {
      enabled = false,
      runId = 0,
      currentTask = nil,
      currentTarget = nil,
      status = "Idle",
      lastReason = "Ready",
      queueCount = 0,
      lastObbyAt = 0,
      bridgeParts = {},
      debugFolder = nil,
      cloverBlacklist = setmetatable({}, { __mode = "k" }),
      cloverFailures = setmetatable({}, { __mode = "k" }),
      cloverQueue = {},
    }

    v63 = {
      pending = false,
      pendingAt = 0,
      running = false,
      lastSignalText = "",
      lastContractAt = 0,
    }

    autoMerchant = _G.__AM
    autoMerchant.running = false
    autoMerchant.busy = false
    autoMerchant.handled = autoMerchant.handled or setmetatable({}, { __mode = "k" })
    autoMerchant.failures = autoMerchant.failures or setmetatable({}, { __mode = "k" })

    function getCharacterMovementParts()
      local character = localPlayer.Character
      return character, character and character:FindFirstChildOfClass("Humanoid"), character and character:FindFirstChild("HumanoidRootPart")
    end

    function getObbyPart()
      local map2 = workspace:FindFirstChild("Map")
      local buffGivers = map2 and map2:FindFirstChild("BuffGivers")
      local obbyBlessing = buffGivers and buffGivers:FindFirstChild("ObbyBlessing")
      return obbyBlessing and obbyBlessing:IsA("BasePart") and obbyBlessing or nil
    end

    function isWaterVoidPart(p22)
      if not p22 or not p22:IsA("BasePart") then
        return false
      end

      if p22.Name == "WaterBlock" then
        return true
      end

      if p22.Name:lower():find("water") then
        return true
      else
        local parent3 = p22.Parent

        while parent3 and parent3 ~= workspace do
          local lower = parent3.Name:lower()

          if lower:find("water") or lower == "waterblocks" or lower == "waterfolder" then
            return true
          end

          parent3 = parent3.Parent
        end

        return false
      end
    end

    function configureAutomationVoidParts()
      local map3 = workspace:FindFirstChild("Map")
      local miscs = map3 and map3:FindFirstChild("Miscs")
      local waterBlocks = miscs and miscs:FindFirstChild("WaterBlocks")

      if waterBlocks then
        for index14, value16 in ipairs(waterBlocks:GetDescendants()) do
          if value16:IsA("BasePart") and value16.Name == "WaterBlock"
            and not value16:FindFirstChild("WaterVoidModifier") then
            local waterVoidModifier2 = Instance.new("PathfindingModifier")
            waterVoidModifier2.Name = "WaterVoidModifier"
            waterVoidModifier2.Label = "WaterVoid"
            waterVoidModifier2.PassThrough = false
            waterVoidModifier2.Parent = value16
          end
        end
      end

      local v163 = getObbyPart()

      if v163 and not v163:FindFirstChild("ObbyBuffVoidModifier") then
        local obbyBuffVoidModifier = Instance.new("PathfindingModifier")
        obbyBuffVoidModifier.Name = "ObbyBuffVoidModifier"
        obbyBuffVoidModifier.Label = "ObbyBuffVoid"
        obbyBuffVoidModifier.PassThrough = false
        obbyBuffVoidModifier.Parent = v163
      end
    end

    function ensureDebugFolder()
      if autoWalk.debugFolder and autoWalk.debugFolder.Parent then
        return autoWalk.debugFolder
      else
        local biomeMacroPathDebug = Instance.new("Folder")
        biomeMacroPathDebug.Name = "BiomeMacroPathDebug"
        biomeMacroPathDebug.Parent = workspace

        autoWalk.debugFolder = biomeMacroPathDebug
        return biomeMacroPathDebug
      end
    end

    function clearPathDebug(p23)
      if not autoWalk.debugFolder then
        return
      end

      for index15, value17 in ipairs(autoWalk.debugFolder:GetChildren()) do
        if not (p23 and value17:IsA("Highlight")) then
          value17:Destroy()
        end
      end
    end

    function updateWorldAutomationMetrics()
    end

    function setWorldStatus(p24, p25)
      autoWalk.status = p24 or "Idle"
      autoWalk.lastReason = p25 or autoWalk.lastReason or "Ready"
      updateWorldAutomationMetrics()
    end

    function logWorld(p26, p27)
      if addLogConsole then
        pcall(function() addLogConsole:Log("World: " .. p26, p27 or "INFO") end)
      end

      local v164 = rawget(_G, "__AF")

      if v164 and v164.StatusLogRef then
        pcall(function()
          local v165 = "World: " .. p26
          v164.StatusLogRef:Log(v165, p27 or "INFO")
        end)
      end
    end

    inputHelper = {}
    inputHelper.inset = guiService:GetGuiInset()
    inputHelper.lastActionAt = 0
    inputHelper.cameraState = nil

    function normalizeUIText(p28)
      return tostring(p28 or ""):lower():gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")
    end

    function inputHelper.pressKey(p29, p30)
      virtualInputManager:SendKeyEvent(true, p29, false, game)
      task.wait(p30 or 0.03)
      virtualInputManager:SendKeyEvent(false, p29, false, game)
    end

    function inputHelper.selectEnter(p31)
      if not p31 or not p31.Parent then
        return false
      end

      guiService.SelectedObject = p31
      task.wait()

      if guiService.SelectedObject ~= p31 or not p31.Parent then
        guiService.SelectedObject = nil
        return false
      end

      inputHelper.pressKey(Enum.KeyCode.Return)
      return true
    end

    function inputHelper.clickAt(p32, p33)
      virtualInputManager:SendMouseMoveEvent(p32, p33, game)
      task.wait(0.01)
      virtualInputManager:SendMouseButtonEvent(p32, p33, 0, true, game, 1)
      task.wait(0.02)
      virtualInputManager:SendMouseButtonEvent(p32, p33, 0, false, game, 1)
    end

    function inputHelper.activateGuiObject(p34, p35, p36)
      if not p34 or not p34.Parent then
        return false
      end

      for k = 1, p36 or 4 do
        local v166 = tick()

        if v166 - inputHelper.lastActionAt < 0.08 then
          task.wait(0.08 - (v166 - inputHelper.lastActionAt))
        end

        if not p34 or not p34.Parent then
          return false
        end

        guiService.SelectedObject = nil
        task.wait(0.03)
        p34.Selectable = true
        guiService.SelectedObject = p34
        task.wait(0.06)

        if guiService.SelectedObject ~= p34 or not p34.Parent then
          guiService.SelectedObject = nil
          task.wait(0.05)
        else
          inputHelper.pressKey(Enum.KeyCode.Return, 0.03)
          task.wait(0.06)
          guiService.SelectedObject = nil
          inputHelper.lastActionAt = tick()

          if p35 then
            local v167 = tick()

            while tick() - v167 < 0.25 do
              if p35() then
                return true
              end

              task.wait(0.02)
            end
          else
            task.wait(0.12)
            return true
          end
        end
      end

      guiService.SelectedObject = nil
      return p35 and p35() or false
    end

    function inputHelper.findDialogChoices()
      local mainInterface = playerGui:FindFirstChild("MainInterface")
      local dialog = mainInterface and mainInterface:FindFirstChild("Dialog")
      local findFirstChild2 = dialog and dialog:FindFirstChild("Choices", true)

      if findFirstChild2 then
        return findFirstChild2
      end

      for index16, value18 in ipairs(playerGui:GetChildren()) do
        if value18.Name == "Choices" then
          return value18
        else
          local findFirstChild3 = value18:FindFirstChild("Choices", true)

          if findFirstChild3 then
            return findFirstChild3
          end
        end
      end

      return nil
    end

    function inputHelper.findDialogChoice(p37, p38)
      local v168 = inputHelper.findDialogChoices()

      if not v168 then
        return nil
      else
        local v169 = normalizeUIText(p37)

        for index17, value19 in ipairs(v168:GetDescendants()) do
          if value19:IsA("TextButton") or value19:IsA("ImageButton") then
            local text4 = value19:IsA("TextButton") and value19.Text or ""
            local findFirstChildWhichIsA2 = value19:FindFirstChildWhichIsA("TextLabel", true)

            if findFirstChildWhichIsA2 and findFirstChildWhichIsA2.Text ~= "" then
              text4 = findFirstChildWhichIsA2.Text
            end

            local v170 = normalizeUIText(text4)

            if v169 ~= "" and v170 == v169 or p38 and p38(v170, value19) then
              return value19
            end
          end
        end

        return nil
      end
    end

    function inputHelper.clickDialogChoice(p39, p40, p41)
      local v171 = tick()
      local v172 = p41 or 6

      while tick() - v171 < v172 do
        local v173 = inputHelper.findDialogChoice(p39, p40)

        if v173 then
          return inputHelper.activateGuiObject(v173, function()
            return not v173.Parent or not v173.Visible or not inputHelper.findDialogChoice(p39, p40)
          end, 4)
        end

        task.wait(0.1)
      end

      return false
    end

    function inputHelper.resolveInventoryRefs()
      local mainInterface2 = playerGui:FindFirstChild("MainInterface")
      local inventory = mainInterface2 and mainInterface2:FindFirstChild("Inventory")
      local items = inventory and inventory:FindFirstChild("Items")
      local itemGrid = items and items:FindFirstChild("ItemGrid")

      local itemGridScrollingFrame = itemGrid
        and itemGrid:FindFirstChild("ItemGridScrollingFrame")

      local search = items and items:FindFirstChild("Search")
      local content = search and search:FindFirstChild("Content")
      local index18 = inventory and inventory:FindFirstChild("Index")
      local itemIndex = index18 and index18:FindFirstChild("ItemIndex")
      local useHolder = itemIndex and itemIndex:FindFirstChild("UseHolder")

      return {
        Main = mainInterface2,
        Inventory = inventory,
        Items = items,
        ItemGrid = itemGridScrollingFrame,
        Search = content,
        UseButton = useHolder and useHolder:FindFirstChild("UseButton"),
        AmountBox = useHolder and useHolder:FindFirstChild("UseAmount"),
      }
    end

    function inputHelper.openInventory()
      local v174 = inputHelper.resolveInventoryRefs()

      if not v174.Inventory or not v174.Items then
        return nil
      else
        v174.Inventory.Visible = true
        task.wait(0.25)
        local itemsTab = nil
        local v175 = tick() + 5

        while not itemsTab and tick() < v175 do
          local v176 = inputHelper.resolveInventoryRefs()
          itemsTab = v176.Items and v176.Items:FindFirstChild("ItemsTab")
          task.wait(0.05)
        end

        if not itemsTab then
          return nil
        end

        inputHelper.selectEnter(itemsTab)
        task.wait(0.15)
        return inputHelper.resolveInventoryRefs()
      end
    end

    function inputHelper.closeInventory()
      local v177 = inputHelper.resolveInventoryRefs()

      if v177.Inventory then
        v177.Inventory.Visible = false
      end

      guiService.SelectedObject = nil
    end

    function inputHelper.clearInventorySearch()
      local v178 = inputHelper.resolveInventoryRefs()

      if v178 and v178.Search then
        v178.Search.Text = ""
        return true
      end

      return false
    end

    function inputHelper.getGuiCenter(index19)
      return math.round(index19.AbsolutePosition.X + index19.AbsoluteSize.X / 2 + inputHelper.inset.X), math.round(index19.AbsolutePosition.Y + index19.AbsoluteSize.Y / 2 + inputHelper.inset.Y)
    end

    function inputHelper.robustActivate(p42, p43)
      if not p42 or not p42.Parent then
        return false
      else
        local v179 = p43 or 3
        local v180 = false

        for m = 1, v179 do
          if not p42 or not p42.Parent then
            return v180
          end

          v180 = inputHelper.activateGuiObject(p42, nil, 2) or v180
          task.wait(0.08)

          if p42 and p42.Parent then
            local v181, v182 = inputHelper.getGuiCenter(p42)
            inputHelper.clickAt(v181, v182)
            v180 = true
          end

          task.wait(0.12)
        end

        return v180
      end
    end

    function inputHelper.findInventoryItem(p44, p45)
      local v183 = p45 or inputHelper.resolveInventoryRefs()

      if not v183.ItemGrid then
        return nil
      else
        local v184 = normalizeUIText(p44)

        for index20, value20 in ipairs(v183.ItemGrid:GetChildren()) do
          if normalizeUIText(value20.Name):find(v184, 1, true) then
            return value20
          end
        end

        return nil
      end
    end

    function inputHelper.findInventoryItemExact(p46, p47)
      local v185 = p47 or inputHelper.resolveInventoryRefs()

      if not v185.ItemGrid then
        return nil
      else
        local gsub = tostring(p46 or ""):lower():gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")

        for index21, value21 in ipairs(v185.ItemGrid:GetChildren()) do
          if tostring(value21.Name or ""):gsub("^Item%s*", ""):lower():gsub("%s+", " "):gsub(
            "^%s*(.-)%s*$", "%1"
          ) == gsub then
            return value21
          end
        end

        return nil
      end
    end

    function inputHelper.useInventoryItemExact(text5, text6, p48)
      local v186 = p48 or {}
      local v187 = "unknown"
      local attempts = v186.Attempts or 3

      for n = 1, attempts do
        local v188 = inputHelper.openInventory()

        if not v188 or not v188.Search or not v188.UseButton or not v188.AmountBox then
          v187 = "inventory_ui_missing"
          task.wait(0.25)
        else
          v188.Search.Text = text5
          task.wait(0.25)
          local v189 = inputHelper.resolveInventoryRefs()
          local v190 = inputHelper.findInventoryItemExact(text5, v189)

          if not v190 then
            v187 = "item_not_found"
            task.wait(0.25)
          else
            local button = v190:FindFirstChild("Button")
              or v190:FindFirstChildOfClass("ImageButton")
              or v190:FindFirstChildOfClass("TextButton")

            if not button then
              v187 = "item_button_missing"
            else
              inputHelper.selectEnter(button)
              task.wait(0.12)
              local v191 = inputHelper.resolveInventoryRefs()

              if not v191.UseButton or not v191.AmountBox then
                v187 = "use_controls_missing"
              else
                v191.AmountBox.Text = tostring(text6 or 1)
                task.wait(0.06)

                if inputHelper.selectEnter(v191.UseButton) then
                  task.wait(0.18)

                  if v186.CloseAfter ~= false then
                    inputHelper.closeInventory()
                  end

                  return true, "used"
                end

                v187 = "use_failed"
              end
            end
          end
        end

        if n < attempts then
          task.wait(0.35)
        end
      end

      if v186.NotifyFailure ~= false then
        errorNotify("- Inventory item failed: " .. tostring(text5) .. " -")
      end

      inputHelper.closeInventory()
      return false, v187
    end

    function inputHelper.useInventoryItem(text7, text8, p49)
      local v192 = p49 or {}
      local v193 = "unknown"
      local attempts2 = v192.Attempts or 3

      for i6 = 1, attempts2 do
        local v194 = inputHelper.openInventory()

        if not v194 or not v194.Search or not v194.UseButton or not v194.AmountBox then
          v193 = "inventory_ui_missing"
          task.wait(0.25)
        else
          v194.Search.Text = text7
          task.wait(0.25)
          local v195 = inputHelper.resolveInventoryRefs()
          local v196 = inputHelper.findInventoryItem(text7, v195)

          if not v196 then
            v193 = "item_not_found"
            task.wait(0.25)
          else
            local button2 = v196:FindFirstChild("Button")
              or v196:FindFirstChildOfClass("ImageButton")
              or v196:FindFirstChildOfClass("TextButton")

            if not button2 then
              v193 = "item_button_missing"
            else
              inputHelper.selectEnter(button2)
              task.wait(0.12)
              local v197 = inputHelper.resolveInventoryRefs()

              if not v197.UseButton or not v197.AmountBox then
                v193 = "use_controls_missing"
              else
                v197.AmountBox.Text = tostring(text8 or 1)
                task.wait(0.06)

                if inputHelper.selectEnter(v197.UseButton) then
                  task.wait(0.18)

                  if v192.CloseAfter ~= false then
                    inputHelper.closeInventory()
                  end

                  return true, "used"
                end

                v193 = "use_failed"
              end
            end
          end
        end

        if i6 < attempts2 then
          task.wait(0.35)
        end
      end

      if v192.NotifyFailure ~= false then
        errorNotify("- Inventory item failed: " .. tostring(text7) .. " -")
      end

      inputHelper.closeInventory()
      return false, v193
    end

    function inputHelper.promptPosition(p50)
      local parent4 = p50 and p50.Parent

      if parent4 and parent4:IsA("Attachment") then
        return parent4.WorldPosition
      elseif parent4 and parent4:IsA("BasePart") then
        return parent4.Position
      else
        local basePart = parent4 and parent4:FindFirstAncestorWhichIsA("BasePart")
        return basePart and basePart.Position or nil
      end
    end

    function inputHelper.activateNearbyPrompts(p51, p52)
      local count2 = 0

      for index22, value22 in ipairs(workspace:GetDescendants()) do
        local v198 = value22

        if v198:IsA("ProximityPrompt") and v198.Enabled then
          local v199 = inputHelper.promptPosition(v198)

          if v199 and (v199 - p51).Magnitude <= (p52 or 40) and fireproximityprompt then
            pcall(function() fireproximityprompt(v198) end)
            count2 = count2 + 1
          end
        end
      end

      return count2
    end

    function inputHelper.findMerchantShopRefs()
      for index23, value23 in ipairs(playerGui:GetChildren()) do
        if value23:IsA("ScreenGui") and value23.Name == "ScreenGui" then
          for index24, value24 in ipairs(value23:GetChildren()) do
            if value24:IsA("Frame") then
              local v200 = {}

              for index25, value25 in ipairs(value24:GetChildren()) do
                if value25:IsA("Frame") then
                  v200[#v200 + 1] = value25
                end
              end

              if #v200 >= 2 then
                local v201 = nil
                local listHolder = nil
                local v202 = nil

                for index26, value26 in ipairs(v200) do
                  local findFirstChild4 = value26:FindFirstChild("ScrollingFrame", true)

                  if findFirstChild4 then
                    v201 = findFirstChild4
                    listHolder = value26
                  else
                    v202 = v202 or value26
                  end
                end

                if v201 and v202 then
                  return {
                    Gui = value23,
                    Outer = value24,
                    ListHolder = listHolder,
                    ControlHolder = v202,
                    ScrollingFrame = v201,
                  }
                end
              end
            end
          end
        end
      end

      return nil
    end

    function inputHelper.merchantShopHasItems(p53)
      if not p53 or not p53.ScrollingFrame or not p53.ScrollingFrame.Parent then
        return false
      end

      for index27, value27 in ipairs(p53.ScrollingFrame:GetDescendants()) do
        if value27:IsA("TextButton") and normalizeUIText(value27.Text) ~= "" then
          return true
        end
      end

      return false
    end

    function inputHelper.waitMerchantShopRefs(p54)
      local v203 = tick()
      local v204 = p54 or 12

      while tick() - v203 < v204 do
        local v205 = inputHelper.findMerchantShopRefs()

        if inputHelper.merchantShopHasItems(v205) then
          return v205
        end

        task.wait(math.min(0.15, math.max(0.03, v204 - (tick() - v203))))
      end

      local v206 = inputHelper.findMerchantShopRefs()

      if inputHelper.merchantShopHasItems(v206) then
        return v206
      end

      return nil
    end

    function inputHelper.findMerchantItemButton(p55, p56)
      if not p55 or not p55.ScrollingFrame then
        return nil
      else
        local v207 = normalizeUIText(p56)

        for index28, value28 in ipairs(p55.ScrollingFrame:GetDescendants()) do
          if value28:IsA("TextButton") and normalizeUIText(value28.Text) == v207 then
            return value28
          end
        end

        return nil
      end
    end

    function inputHelper.findMerchantQuantityBox(p57)
      if not p57 or not p57.ControlHolder then
        return nil
      else
        local findFirstChild5 = p57.ControlHolder:FindFirstChild("TextBox", true)
        return findFirstChild5 and findFirstChild5:IsA("TextBox") and findFirstChild5 or nil
      end
    end

    function inputHelper.findMerchantSetMaxButton(p58)
      if not p58 or not p58.ControlHolder then
        return nil
      end

      for index29, value29 in ipairs(p58.ControlHolder:GetDescendants()) do
        if value29:IsA("ImageButton") then
          local findFirstChildWhichIsA3 = value29:FindFirstChildWhichIsA("TextLabel", true)

          if findFirstChildWhichIsA3
            and normalizeUIText(findFirstChildWhichIsA3.Text) == "set to max" then
            return value29
          end
        end
      end

      return nil
    end

    function inputHelper.findMerchantBuyButton(p59)
      if not p59 or not p59.ControlHolder then
        return nil
      else
        local v208 = inputHelper.findMerchantSetMaxButton(p59)

        for index30, value30 in ipairs(p59.ControlHolder:GetChildren()) do
          if value30:IsA("Frame") then
            local v209 = nil
            local count3 = 0

            for index31, value31 in ipairs(value30:GetChildren()) do
              if value31:IsA("ImageButton") then
                count3 = count3 + 1
                v209 = value31
              end
            end

            if count3 == 1 and v209 and v209.Name == "ImageButton" and v209 ~= v208 then
              return v209
            end
          end
        end

        for index32, value32 in ipairs(p59.ControlHolder:GetDescendants()) do
          if value32:IsA("ImageButton") and value32.Name == "ImageButton" and value32 ~= v208 then
            local findFirstChildWhichIsA4 = value32:FindFirstChildWhichIsA("TextLabel", true)

            if not findFirstChildWhichIsA4
              or normalizeUIText(findFirstChildWhichIsA4.Text) ~= "set to max" then
              return value32
            end
          end
        end

        return nil
      end
    end

    function inputHelper.buyMerchantItem(p60, text9, p61, p62)
      local v210 = tick()
      local v211, v212, v213, v214

      while tick() - v210 < (p62 or 10) do
        local v215 = inputHelper.findMerchantShopRefs()
        local v216 = v215 and inputHelper.findMerchantItemButton(v215, p60)

        if v216 then
          inputHelper.robustActivate(v216, 2)
          task.wait(0.18)
          local v217 = inputHelper.findMerchantShopRefs() or v215

          if p61 then
            local v218 = inputHelper.findMerchantSetMaxButton(v217)

            if v218 then
              inputHelper.robustActivate(v218, 2)
              task.wait(0.12)
              v211 = inputHelper.findMerchantShopRefs()

              v212 = v211
              v212 = v211 or v217

              v213 = inputHelper.findMerchantBuyButton(v212)

              if not v213 then
                return false, "buy_button_missing"
              end

              inputHelper.robustActivate(v213, 3)
              task.wait(0.35)
              return true, "bought"
            end

            return false, "set_max_missing"
          end

          v214 = inputHelper.findMerchantQuantityBox(v217)

          if v214 then
            v214.Text = tostring(math.max(1, math.floor(tonumber(text9) or 1)))

            pcall(function()
              v214:CaptureFocus()
              v214:ReleaseFocus()
            end)

            task.wait(0.08)
            v211 = inputHelper.findMerchantShopRefs()

            v212 = v211
            v212 = v211 or v217

            v213 = inputHelper.findMerchantBuyButton(v212)

            if not v213 then
              return false, "buy_button_missing"
            end

            inputHelper.robustActivate(v213, 3)
            task.wait(0.35)
            return true, "bought"
          end

          return false, "amount_box_missing"
        end

        task.wait(0.15)
      end

      return false, "item_unavailable"
    end

    function inputHelper.closeMerchantShop()
      local v219 = inputHelper.findMerchantShopRefs()
      local v220 = {}

      if v219 and v219.Outer then
        v220[#v220 + 1] = v219.Outer
      end

      for index33, value33 in ipairs(playerGui:GetChildren()) do
        if value33:IsA("ScreenGui") and value33.Name == "ScreenGui" then
          for index34, value34 in ipairs(value33:GetChildren()) do
            if value34:IsA("Frame") then
              v220[#v220 + 1] = value34
            end
          end
        end
      end

      for index35, value35 in ipairs(v220) do
        local findFirstChild6 = value35:FindFirstChild("TextLabel", true)

        if findFirstChild6 and findFirstChild6:IsA("TextLabel") then
          local findFirstChildWhichIsA5 = findFirstChild6:FindFirstChildWhichIsA(
            "TextButton", true
          )

          if findFirstChildWhichIsA5 then
            inputHelper.robustActivate(findFirstChildWhichIsA5, 3)
            task.wait(0.15)
            return true
          end
        end
      end

      return false
    end

    function inputHelper.setLookDownCamera(p63, p64)
      local currentCamera = workspace.CurrentCamera

      if not currentCamera or not p63 then
        return
      end

      pcall(function()
        if not inputHelper.cameraState then
          inputHelper.cameraState = {
            Type = currentCamera.CameraType,
            Subject = currentCamera.CameraSubject,
            MinZoom = localPlayer.CameraMinZoomDistance,
            MaxZoom = localPlayer.CameraMaxZoomDistance,
          }
        end

        currentCamera.CameraType = Enum.CameraType.Custom
        local v221, v222 = getCharacterMovementParts()

        if v222 then
          currentCamera.CameraSubject = v222
        end

        local v223 = p64 or 70

        localPlayer.CameraMaxZoomDistance = math.max(localPlayer.CameraMaxZoomDistance, v223)

        localPlayer.CameraMinZoomDistance = math.min(
          math.max(v223 * 0.45, 20), localPlayer.CameraMaxZoomDistance
        )
      end)
    end

    function inputHelper.setLookAtCamera(p65, index36, index37)
      local currentCamera2 = workspace.CurrentCamera

      if not currentCamera2 or not p65 or not index36 then
        return
      end

      pcall(function()
        if not inputHelper.cameraState then
          inputHelper.cameraState = {
            Type = currentCamera2.CameraType,
            Subject = currentCamera2.CameraSubject,
            MinZoom = localPlayer.CameraMinZoomDistance,
            MaxZoom = localPlayer.CameraMaxZoomDistance,
          }
        end

        local vector = p65.Position - index36

        if vector.Magnitude < 2 then
          vector = Vector3.new(0, 0, 1)
        end

        local position = p65.Position
        local vector2 = Vector3.new(0, 7, 0)
        local unit = vector.Unit

        currentCamera2.CameraType = Enum.CameraType.Scriptable

        currentCamera2.CFrame = CFrame.lookAt(
          position + vector2 + unit * (index37 or 18), index36 + Vector3.new(0, 3, 0)
        )
      end)
    end

    function inputHelper.restoreCamera()
      local currentCamera3 = workspace.CurrentCamera

      if currentCamera3 then
        pcall(function()
          if inputHelper.cameraState then
            currentCamera3.CameraType = inputHelper.cameraState.Type or Enum.CameraType.Custom
            currentCamera3.CameraSubject = inputHelper.cameraState.Subject

            localPlayer.CameraMinZoomDistance = inputHelper.cameraState.MinZoom
              or localPlayer.CameraMinZoomDistance

            localPlayer.CameraMaxZoomDistance = inputHelper.cameraState.MaxZoom
              or localPlayer.CameraMaxZoomDistance
          else
            currentCamera3.CameraType = Enum.CameraType.Custom
          end
        end)
      end

      inputHelper.cameraState = nil
    end

    function clearTargetHighlight()
      for index38, value36 in ipairs(ensureDebugFolder():GetChildren()) do
        if value36:IsA("Highlight") then
          value36:Destroy()
        end
      end
    end

    function setTargetHighlight(p66, p67)
      clearTargetHighlight()

      if not p66 then
        return
      else
        local parent5 = ensureDebugFolder()

        local currentTargetHighlight = Instance.new("Highlight")
        currentTargetHighlight.Name = "CurrentTargetHighlight"
        currentTargetHighlight.Adornee = p66
        currentTargetHighlight.FillColor = p67 or Color3.fromRGB(90, 255, 160)
        currentTargetHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        currentTargetHighlight.FillTransparency = 0.75
        currentTargetHighlight.Parent = parent5

        return
      end
    end

    function drawDebugPath(p68)
      if not userConfig.PathDebug then
        clearPathDebug(true)
        return
      else
        local parent6 = ensureDebugFolder()
        clearPathDebug(true)
        local position2 = nil

        for index39, value37 in ipairs(p68 or {}) do
          local v224 = value37.Action == Enum.PathWaypointAction.Jump

          local part = Instance.new("Part")
          part.Name = "Waypoint_" .. index39
          part.Shape = Enum.PartType.Ball
          part.Size = v224 and Vector3.new(1.05, 1.05, 1.05) or Vector3.new(0.72, 0.72, 0.72)
          part.Anchored = true
          part.CanCollide = false
          part.Material = Enum.Material.Neon
          part.Color = v224 and Color3.fromRGB(255, 220, 90) or Color3.fromRGB(130, 255, 210)
          part.Position = value37.Position + Vector3.new(0, 0.35, 0)
          part.Parent = parent6

          if position2 then
            local v225 = part.Position - position2

            for index40, value38 in ipairs({
              {
                Name = "PathLine",
                Size = 0.16,
                Transparency = 0.08,
                Color = Color3.fromRGB(255, 235, 90),
              },
              {
                Name = "PathShadow",
                Size = 0.28,
                Transparency = 0.82,
                Color = Color3.fromRGB(80, 255, 190),
              },
            }) do
              local part2 = Instance.new("Part")
              part2.Name = value38.Name .. "_" .. index39
              part2.Anchored = true
              part2.CanCollide = false
              part2.Material = Enum.Material.Neon
              part2.Transparency = value38.Transparency
              part2.Color = value38.Color
              part2.Size = Vector3.new(value38.Size, value38.Size, v225.Magnitude)
              part2.CFrame = CFrame.lookAt(position2 + v225 * 0.5, part.Position)
              part2.Parent = parent6
            end
          end

          position2 = part.Position
        end

        return
      end
    end

    function clearDebugProgress(p69)
      if not autoWalk.debugFolder then
        return
      end

      for index41, value39 in ipairs(autoWalk.debugFolder:GetChildren()) do
        local d = value39.Name:match("_(%d+)$")

        if d and tonumber(d) <= p69 then
          value39:Destroy()
        end
      end
    end

    function createSafePath(p70, p71)
      local path = pathfindingService:CreatePath({
        AgentRadius = 3,
        AgentHeight = 6,
        AgentCanJump = true,
        AgentJumpHeight = 16,
        AgentMaxSlope = 55,
        WaypointSpacing = 3,
        Costs = { WaterVoid = 1000000, ObbyBuffVoid = 1000000 },
      })

      if not pcall(function() path:ComputeAsync(p70, p71) end)
        or path.Status ~= Enum.PathStatus.Success then
        return nil
      end

      return path
    end

    function getApproachPositions(index42)
      local v226 = { index42 }

      for index43, value40 in ipairs({ 5, 10 }) do
        for i7 = 0, 3 do
          local v227 = i7 / 4 * math.pi * 2

          v226[#v226 + 1] = index42
            + Vector3.new(math.cos(v227) * value40, 0, math.sin(v227) * value40)
        end
      end

      return v226
    end

    function pathTravelLength(p72)
      local total = 0
      local getWaypoints = p72:GetWaypoints()

      for i8 = 2, #getWaypoints do
        total = total + (getWaypoints[i8].Position - getWaypoints[i8 - 1].Position).Magnitude
      end

      return total
    end

    function findBestPathTo(index44)
      local v228, v229, v230 = getCharacterMovementParts()

      if not v230 then
        return nil, index44, "no_root"
      else
        local huge = math.huge
        local v231 = nil
        local v232 = nil

        local candidates = getApproachPositions(index44)
        local fastWalk = userConfig.FastWalk ~= false
        local startPos = v230.Position

        if fastWalk then
          -- GYESG: look at the most promising approach points first ...
          table.sort(candidates, function(a, b)
            return (startPos - a).Magnitude + (a - index44).Magnitude * 0.5
              < (startPos - b).Magnitude + (b - index44).Magnitude * 0.5
          end)
        end

        for index45, value41 in ipairs(candidates) do
          -- ... and skip every point that cannot beat the best route found so far (6 studs of slack for snapping)
          local lowerBound = math.max(0, (startPos - value41).Magnitude - 6) + (value41 - index44).Magnitude * 0.5

          if not (fastWalk and v232 and lowerBound >= huge) then
            local v233 = createSafePath(v230.Position, value41)

            if v233 then
              local v234 = pathTravelLength(v233) + (value41 - index44).Magnitude * 0.5

              if v234 < huge then
                v231 = value41
                huge = v234
                v232 = v233
              end
            end
          end
        end

        if v232 then
          return v232, v231, "ok"
        end

        return nil, index44, "no_path"
      end
    end

    function triggerTargetPart(p73)
      if not p73 or not p73:IsA("BasePart") then
        return false
      end

      local v235
      v1277, v1276, v235 = getCharacterMovementParts()
      local v236 = false

      if v235 and firetouchinterest then
        pcall(function()
          firetouchinterest(v235, p73, 0)
          task.wait(0.05)
          firetouchinterest(v235, p73, 1)
          v236 = true
        end)
      end

      for index46, value42 in ipairs(p73:GetDescendants()) do
        local v237 = value42

        if v237:IsA("ProximityPrompt") and v237.Enabled and fireproximityprompt then
          pcall(function()
            fireproximityprompt(v237)
            v236 = true
          end)
        end
      end

      return v236
    end

    function waitForCloverGone(p74, p75)
      local v238, v239, v240 = getCharacterMovementParts()

      if not v239 or not v240 then
        return false, "no_character"
      else
        local v241 = tick()
        local v242 = tick()
        local huge2 = math.huge

        while tick() - v241 < 12 do
          if not p74 or not p74.Parent or not p75 or not p75.Parent then
            return true, "collected"
          else
            local magnitude = (v240.Position - p75.Position).Magnitude

            if magnitude < huge2 - 0.35 then
              huge2 = magnitude
              v242 = tick()
            end

            if magnitude > 2.5 then
              v239:MoveTo(p75.Position)
            else
              triggerTargetPart(p75)
            end

            if tick() - v242 > 5 and magnitude > 7 then
              return false, "stuck"
            end

            task.wait(0.15)
          end
        end

        if not p74.Parent or not p75.Parent then
          return true, "collected"
        end

        return false, "not_collected"
      end
    end

    function pointNeedsBridge(index47)
      local raycastParams = RaycastParams.new()
      raycastParams.FilterType = Enum.RaycastFilterType.Exclude

      local character2 = localPlayer.Character

      raycastParams.FilterDescendantsInstances = character2 and { character2 } or {}
      raycastParams.IgnoreWater = true

      local raycast = workspace:Raycast(
        index47 + Vector3.new(0, 4, 0), Vector3.new(0, -16, 0), raycastParams
      )

      if not raycast then
        return true
      end

      if isWaterVoidPart(raycast.Instance) then
        return true
      end

      return index47.Y - raycast.Position.Y > 6
    end

    function createBridgeBetween(index48, p76, p77)
      local biomeMacroTempBridge

      if p77 == Enum.PathWaypointAction.Jump then
        return
      else
        local v243 = p76 - index48
        local magnitude2 = Vector3.new(v243.X, 0, v243.Z).Magnitude
        local v244 = math.abs(v243.Y)

        if magnitude2 < 9 then
          return
        elseif v244 > 3.5 then
          return
        else
          local v245 = index48 + v243 * 0.5

          if not pointNeedsBridge(v245) then
            return
          else
            biomeMacroTempBridge = Instance.new("Part")
            biomeMacroTempBridge.Name = "BiomeMacroTempBridge"
            biomeMacroTempBridge.Anchored = true
            biomeMacroTempBridge.CanCollide = true
            biomeMacroTempBridge.Transparency = userConfig.PathDebug and 0.45 or 1
            biomeMacroTempBridge.Material = Enum.Material.ForceField
            biomeMacroTempBridge.Color = Color3.fromRGB(80, 255, 170)
            biomeMacroTempBridge.Size = Vector3.new(math.max(5, magnitude2 + 4), 0.28, 4.5)

            local vector3 = Vector3.new(p76.X, v245.Y, p76.Z)

            biomeMacroTempBridge.CFrame = CFrame.lookAt(v245 - Vector3.new(0, 2.8, 0), vector3)
              * CFrame.Angles(0, math.rad(90), 0)

            biomeMacroTempBridge.Parent = workspace

            autoWalk.bridgeParts[#autoWalk.bridgeParts + 1] = biomeMacroTempBridge

            task.delay(20, function()
              if biomeMacroTempBridge and biomeMacroTempBridge.Parent then
                biomeMacroTempBridge:Destroy()
              end
            end)

            return biomeMacroTempBridge
          end
        end
      end
    end

    function clearTempBridges()
      for index49, value43 in ipairs(autoWalk.bridgeParts) do
        if value43 and value43.Parent then
          value43:Destroy()
        end
      end

      autoWalk.bridgeParts = {}
    end

    function createObbyAssistRoute(p78, p79)
      clearTempBridges()
      local v246 = {}
      local v247

      for index50, value44 in ipairs({
        {
          Vector3.new(166.544312, 90.250015, -575.563599),
          Vector3.new(171.425262, 86.75, -577.46582),
        },
        {
          Vector3.new(180.154968, 86.75, -586.787964),
          Vector3.new(185.813522, 86.75, -593.228333),
        },
        {
          Vector3.new(189.663025, 86.75, -599.417114),
          Vector3.new(194.160141, 87.000023, -603.993958),
        },
        { Vector3.new(183.468796, 98, -676.687134), Vector3.new(173.402405, 95, -679.152283) },
        { Vector3.new(139.234726, 91, -678.231689), Vector3.new(132.657394, 95, -678.39032) },
        { Vector3.new(96.119041, 98, -650.28363), Vector3.new(87.594765, 99, -646.465515) },
      }) do
        local v248 = value44[2]
        local v249 = value44[1]
        local magnitude3 = (v248 - v249).Magnitude

        if magnitude3 > 0.5 then
          local part3 = Instance.new("Part")
          part3.Name = "BiomeMacroObbyManualBridge_" .. index50
          part3.Anchored = true
          part3.CanCollide = true
          part3.CanTouch = false
          part3.Material = Enum.Material.SmoothPlastic
          part3.Color = Color3.fromRGB(75, 230, 170)
          part3.Transparency = userConfig.PathDebug and 0.72 or 1
          part3.Size = Vector3.new(7, 0.45, magnitude3 + 3)
          part3.CFrame = CFrame.lookAt(v249:Lerp(v248, 0.5), v248)
          part3.Parent = workspace

          autoWalk.bridgeParts[#autoWalk.bridgeParts + 1] = part3
        end

        for index51, value45 in ipairs({ v249, v248 }) do
          local v250 = #v246 + 1

          v246[v250] = {
            Position = value45,
            Action = v247 and value45.Y - v247.Y > 1.8 and Enum.PathWaypointAction.Jump
              or Enum.PathWaypointAction.Walk,
          }

          v247 = value45
        end
      end

      return #autoWalk.bridgeParts > 0, v246
    end

    function targetLooksLikeObbyArea(p80)
      if not p80 then
        return false
      end

      return p80.X >= 45 and p80.X <= 230 and p80.Z >= -730 and p80.Z <= -520 and p80.Y >= 65
        and p80.Y <= 135
    end

    function findObbyGroundPoint(index52)
      local raycastParams2 = RaycastParams.new()
      raycastParams2.FilterType = Enum.RaycastFilterType.Exclude

      local character3 = localPlayer.Character

      raycastParams2.FilterDescendantsInstances = character3 and { character3 } or {}
      raycastParams2.IgnoreWater = true

      local raycast2 = workspace:Raycast(
        index52 + Vector3.new(0, 18, 0), Vector3.new(0, -80, 0), raycastParams2
      )

      if not raycast2 or not raycast2.Instance or isWaterVoidPart(raycast2.Instance) then
        return nil
      end

      return raycast2.Position + Vector3.new(0, 3, 0)
    end

    function getMerchantPathPosition(p81)
      local v251 = getModelPosition(p81)

      if not v251 then
        return nil
      end

      return findObbyGroundPoint(v251) or v251
    end

    function appendPathWaypoints(index53, p82)
      for index54, value46 in ipairs(p82:GetWaypoints()) do
        index53[#index53 + 1] = value46
      end
    end

    function appendManualWaypoint(index55, p83, p84)
      local v252 = findObbyGroundPoint(p83) or p83
      local v253 = #index55 + 1

      index55[v253] = {
        Position = v252,
        Action = p84 and v252.Y - p84.Y > 1.8 and Enum.PathWaypointAction.Jump
          or Enum.PathWaypointAction.Walk,
      }
    end

    function sanitizeWaypoints(p85)
      if not p85 then
        return p85
      else
        local v254 = {}

        for index56, value47 in ipairs(p85) do
          if value47.Action == Enum.PathWaypointAction.Jump then
            v254[#v254 + 1] = value47
          else
            local v255 = findObbyGroundPoint(value47.Position)

            if v255 and math.abs(v255.Y - value47.Position.Y) > 4 then
              v254[#v254 + 1] = { Position = v255, Action = value47.Action }
            else
              v254[#v254 + 1] = value47
            end
          end
        end

        return v254
      end
    end

    function appendTerrainWalkWaypoints(p86, p87, p88, p89)
      local v256 = p89 or 12
      local magnitude4 = (p88 - p87).Magnitude

      if magnitude4 < 1 then
        return true
      else
        local v257 = math.clamp(math.ceil(magnitude4 / v256), 1, 80)
        local v258 = p87

        for i9 = 1, v257 do
          local v259 = findObbyGroundPoint((p87:Lerp(p88, i9 / v257)))

          if not v259 then
            return false
          end

          appendManualWaypoint(p86, v259, v258)
          v258 = v259
        end

        return true
      end
    end

    function buildObbyManualWaypoints(p90, p91, p92)
      local v260 = p90
      local v261 = {}
      local v262 = 1
      local huge3 = math.huge
      local v263

      for index57, value48 in ipairs(p91) do
        local magnitude5 = (value48.Position - p90).Magnitude

        if magnitude5 < huge3 then
          huge3 = magnitude5
          v263 = index57
        end
      end

      if v263 and huge3 <= 35 then
        v262 = v263

        if huge3 <= 7 or v263 % 2 == 0 then
          v262 = v263 + 1
        end
      end

      for i10 = v262, #p91 do
        local position3 = p91[i10].Position

        if i10 % 2 == 1 then
          local v264 = createSafePath(v260, position3)

          if v264 then
            appendPathWaypoints(v261, v264)
          elseif (position3 - v260).Magnitude <= 22 then
            appendManualWaypoint(v261, position3, v260)
          elseif not appendTerrainWalkWaypoints(v261, v260, position3, 10) then
            return nil, "manual_segment_no_path_" .. tostring(i10)
          end
        else
          appendManualWaypoint(v261, position3, v260)
        end

        v260 = position3
      end

      local v265 = createSafePath(v260, p92)

      if v265 then
        appendPathWaypoints(v261, v265)
        return v261, "manual_obby_route"
      elseif (p92 - v260).Magnitude <= 30 then
        appendManualWaypoint(v261, p92, v260)
        return v261, "manual_obby_route"
      else
        if not appendTerrainWalkWaypoints(v261, v260, p92, 10) then
          return nil, "manual_final_no_path"
        end

        return v261, "manual_obby_route"
      end
    end

    function recoverPathMovement(p93, index58, p94, p95, index59)
      if not p93 or not index58 then
        return
      else
        if p95 ~= "fishing" then
          setWorldStatus(
            "Recovering", string.format("%s recovery %d", p95 or "path", index59 or 1)
          )
        end

        local v266 = index58.Position - p94

        if v266.Magnitude < 1 then
          v266 = -index58.CFrame.LookVector
        end

        local v267 = math.clamp(5 + (index59 or 1) * 2, 6, 12)
        local v268 = index58.Position + v266.Unit * v267

        for index60, value49 in ipairs({
          v266.Unit, -index58.CFrame.LookVector, index58.CFrame.RightVector,
          -index58.CFrame.RightVector,
        }) do
          local v269 = findObbyGroundPoint(index58.Position + value49 * v267)

          if v269 then
            v268 = v269
            break
          end
        end

        p93:MoveTo(v268)
        task.wait(0.18)
        local getState = p93:GetState()

        if getState == Enum.HumanoidStateType.Jumping
          or getState == Enum.HumanoidStateType.Freefall then
          local v270 = tick()

          while tick() - v270 < 1.2 do
            local getState2 = p93:GetState()

            if getState2 ~= Enum.HumanoidStateType.Jumping
              and getState2 ~= Enum.HumanoidStateType.Freefall then
              break
            end

            task.wait(0.05)
          end

          task.wait(0.1)
        end

        local getState3 = p93:GetState()

        if getState3 == Enum.HumanoidStateType.Running
          or getState3 == Enum.HumanoidStateType.RunningNoPhysics
          or getState3 == Enum.HumanoidStateType.Landed then
          p93:ChangeState(Enum.HumanoidStateType.Jumping)
          task.wait(0.16)
        end

        p93:MoveTo(p94)
        return
      end
    end

    function autoPathMoveTo(p96, p97, p98, p99)
      configureAutomationVoidParts()
      local v271, v272, v273 = getCharacterMovementParts()
      local v274 = v273

      if not v272 or not v274 or v272.Health <= 0 then
        return false, "no_character"
      end

      if p98 ~= "fishing" then
        setWorldStatus("Pathing", p98 or "target")
      end

      local v275 = p98 == "obby" or p98 == "merchant" and targetLooksLikeObbyArea(p96)
      local v276 = false
      local v277 = nil

      if v275 then
        setWorldStatus(p98 == "obby" and "Obby" or "Merchant", "Preparing bridges")
        v276, v277 = createObbyAssistRoute(v274.Position, p96)

        if v276 then
          task.wait(0.12)
        end
      end

      local v278 = nil
      local v279 = nil
      local v280 = nil
      local getWaypoints2 = nil
      local f10, f11, f12, v281, v282, v283, v284, v285, v286, f13, v287

      if v275 and v276 and v277 and #v277 > 0 then
        getWaypoints2, v280 = buildObbyManualWaypoints(v274.Position, v277, p96)

        if not getWaypoints2 then
          clearTempBridges()
          return false, v280 or "manual_obby_no_path"
        end

        getWaypoints2 = sanitizeWaypoints(getWaypoints2)

        if not getWaypoints2 or #getWaypoints2 == 0 then
          clearTempBridges()
          return false, "manual_obby_no_safe_waypoints"
        end
      else
        local v310, v311
        v278, v310, v311 = findBestPathTo(p96)
        v279 = v310
        v280 = v311

        if not v278 then
          if v276 then
            clearTempBridges()
          end

          return false, v280 or "no_path"
        end

        getWaypoints2 = v278:GetWaypoints()
        getWaypoints2 = GYESG.simplify(sanitizeWaypoints(getWaypoints2))

        if not getWaypoints2 or #getWaypoints2 == 0 then
          return false, "no_safe_waypoints"
        end
      end

      -- FIX: this walking part is shared by both path modes (was a goto into a nested block)
      drawDebugPath(getWaypoints2)

      if p97 then
        setTargetHighlight(p97, p98 == "obby" and Color3.fromRGB(255, 210, 80)
          or Color3.fromRGB(90, 255, 160))
      end

      v285 = nil
      v286 = nil

      function f13(p100)
        if v286 then
          v286:Disconnect()
        end

        local connect = p100
        v285 = nil

        if p100 then
          connect = p100.Blocked:Connect(function(p101) v285 = p101 end)
        end

        v286 = connect or nil
      end

      f13(v278)

      function f10()
        if p98 == "obby" and not userConfig.AutoObbyLuckBoost then
          return true
        end

        if p98 == "clover" and not userConfig.AutoCollectClover then
          return true
        end

        if p98 == "eden" and (not userConfig.AutoContractWithEden or not v63.running) then
          return true
        end

        if p98 == "merchant"
          and (not userConfig.AutoMerchant or not userConfig.AutoMerchant.Enabled or not autoMerchant.running) then
          return true
        end

        if p99 then
          return not p99()
        end

        return autoWalk.runId <= 0
      end

      function f11(p102, p103)
        if v286 then
          v286:Disconnect()
        end

        clearPathDebug(false)

        if v276 then
          clearTempBridges()
        end

        return p102, p103
      end

      v287 = 0

      function f12(p104)
        v287 = v287 + 1

        if v287 > 3 then
          return false, p104 or "repath_limit"
        else
          local v288, v289, v290 = getCharacterMovementParts()

          if not v289 or not v290 or v289.Health <= 0 then
            return false, "no_character"
          end

          v272 = v289
          v274 = v290

          if p98 ~= "fishing" then
            setWorldStatus(
              "Repathing", string.format("%s recovery path %d", p98 or "target", v287)
            )
          end

          if v275 and v276 and v277 and #v277 > 0 then
            local v291
            getWaypoints2, v291 = buildObbyManualWaypoints(v274.Position, v277, p96)
            v280 = v291

            if getWaypoints2 then
              getWaypoints2 = sanitizeWaypoints(getWaypoints2)
            end

            v278 = nil
            v279 = nil
            f13(nil)
          else
            local v292, v293
            v278, v292, v293 = findBestPathTo(p96)
            v279 = v292
            v280 = v293
            getWaypoints2 = v278 and v278:GetWaypoints() or nil

            if getWaypoints2 then
              getWaypoints2 = GYESG.simplify(sanitizeWaypoints(getWaypoints2))
            end

            f13(v278)
          end

          if not getWaypoints2 or #getWaypoints2 == 0 then
            return false, v280 or "repath_failed"
          end

          clearPathDebug(true)
          drawDebugPath(getWaypoints2)
          v285 = nil
          return true, "repathed"
        end
      end

      v281 = 1

      while v281 <= #getWaypoints2 do
        local v294 = getWaypoints2[v281]

        if f10() then
          return f11(false, "disabled")
        end

        if userConfig.AutomationPriority and autoWalk.currentTask == "clover" and userConfig.AutoObbyLuckBoost
          and autoWalk.lastObbyAt > 0 and tick() >= autoWalk.lastObbyAt + 120 then
          return f11(false, "preempted")
        end

        if v285 and v285 <= v281 then
          v285 = nil
          local v295, v296 = f12("blocked")

          if v295 then
            v281 = 1
          else
            return f11(false, v296 or "blocked")
          end
        else
          if p98 ~= "fishing" then
            setWorldStatus("Moving", string.format(
              "%s waypoint %d/%d", p98 or "target", v281, #getWaypoints2
            ))
          end

          local v297 = nil

          if not v275 then
            v297 = createBridgeBetween(v274.Position, v294.Position, v294.Action)
          end

          if v294.Action == Enum.PathWaypointAction.Jump then
            v272:ChangeState(Enum.HumanoidStateType.Jumping)
          end

          v272:MoveTo(v294.Position)
          local v298 = false
          local connect2 = v272.MoveToFinished:Connect(function(p105) v298 = p105 end)
          local v299 = tick()

          local v300 = math.clamp((v274.Position - v294.Position).Magnitude
            / (v275 and 7 or 9), 1.2, v275 and 8 or 6)

          local magnitude6 = (v274.Position - v294.Position).Magnitude
          local v301 = tick()
          local position4 = v274.Position
          local count4 = 0

          while tick() - v299 < v300 do
            local v302, v303, v304 = getCharacterMovementParts()

            if v303 then
              v272 = v303
            end

            if v304 then
              v274 = v304
            end

            if not v274 or not v274.Parent or not v272 or v272.Health <= 0 then
              if connect2 then
                connect2:Disconnect()
              end

              if v297 and v297.Parent then
                v297:Destroy()
              end

              return f11(false, "no_character")
            elseif f10() then
              if connect2 then
                connect2:Disconnect()
              end

              if v297 and v297.Parent then
                v297:Destroy()
              end

              return f11(false, "disabled")
            else
              local magnitude7 = (v274.Position - v294.Position).Magnitude

              if v298 or magnitude7 < 4 then
                break
              else
                if magnitude7 < magnitude6 - 0.55 then
                  magnitude6 = magnitude7
                  v301 = tick()
                end

                local magnitude8 = (v274.Position - position4).Magnitude
                local v305 = magnitude8 >= 30

                local v306 = magnitude8 > 13 and magnitude8 < 30
                  and magnitude7 > magnitude6 + 5

                if v305 then
                  magnitude6 = magnitude7
                  local v307 = v272
                  v301 = tick()
                  v307:MoveTo(v294.Position)
                elseif (v306 or tick() - v301 > 0.9) and count4 < 3 then
                  count4 = count4 + 1
                  recoverPathMovement(v272, v274, v294.Position, p98, count4)
                  v300 = v300 + 1.2
                  v301 = tick()
                elseif tick() - v301 > 1.8 and count4 >= 3 then
                  break
                end

                position4 = v274.Position
                task.wait(0.05)
              end
            end
          end

          if connect2 then
            connect2:Disconnect()
          end

          if not v298 and (v274.Position - v294.Position).Magnitude >= 7 then
            if v297 and v297.Parent then
              v297:Destroy()
            end

            local v308, v309 = f12("stuck")

            if v308 then
              v281 = 1
            else
              return f11(false, v309 or "stuck")
            end
          else
            if v297 and v297.Parent then
              v297:Destroy()
            end

            clearDebugProgress(v281)
            v281 = v281 + 1
          end
        end
      end

      v284, v283, v282 = getCharacterMovementParts()

      if v283 then
        v272 = v283
      end

      if v282 then
        v274 = v282
      end

      if not v274 or not v274.Parent or not v272 or v272.Health <= 0 then
        return f11(false, "no_character")
      end

      if p98 == "obby" and (v274.Position - p96).Magnitude > 5
        and (v274.Position - p96).Magnitude <= 35 then
        v272:MoveTo(p96)
        task.wait(0.45)
      elseif v279 and (v274.Position - p96).Magnitude > 5 and p98 ~= "obby" then
        v272:MoveTo(p96)
        task.wait(0.3)
      end

      return f11(true, "ok")
    end

    function moveWithPathfinding(p106, p107)
      local v312 = p107 or {}
      return autoPathMoveTo(p106, v312.Target, v312.TaskName, v312.IsActive)
    end

    function isCloverModel(p108)
      return p108 and p108.Name == "Model" and p108:FindFirstChild("Hitox", true) ~= nil
    end

    function rebuildCloverQueue()
      autoWalk.cloverQueue = {}
      local map4 = workspace:FindFirstChild("Map")

      if not map4 then
        autoWalk.queueCount = 0
        updateWorldAutomationMetrics()
        return
      else
        local v313, v314, v315 = getCharacterMovementParts()

        if not v315 then
          autoWalk.queueCount = 0
          updateWorldAutomationMetrics()
          return
        end

        for index61, value50 in ipairs(map4:GetDescendants()) do
          if isCloverModel(value50) and not autoWalk.cloverBlacklist[value50] then
            local findFirstChild7 = value50:FindFirstChild("Hitox", true)

            local position5 = findFirstChild7

            position5 = findFirstChild7 and findFirstChild7:IsA("BasePart")
              and findFirstChild7.Position

            if position5 then
              local magnitude9 = (v315.Position - position5).Magnitude

              if magnitude9 <= 1800 then
                autoWalk.cloverQueue[#autoWalk.cloverQueue + 1] = {
                  model = value50,
                  hitox = findFirstChild7,
                  dist = magnitude9,
                }
              end
            end
          end
        end

        table.sort(autoWalk.cloverQueue, function(p109, p110) return p109.dist < p110.dist end)
        autoWalk.queueCount = #autoWalk.cloverQueue
        updateWorldAutomationMetrics()
        return
      end
    end

    function blacklistClover(key5, p111)
      if not key5 then
        return
      end

      autoWalk.cloverBlacklist[key5] = true
      task.delay(p111 or 45, function() autoWalk.cloverBlacklist[key5] = nil end)
    end

    function waitForObbyTeleport(p112, p113)
      local v316 = 0
      local v317 = tick()

      while tick() - v317 < 9 do
        local v318, v319, v320 = getCharacterMovementParts()

        if not v319 or v319.Health <= 0 then
          return false, "no_character"
        end

        if v320 and p113 and (v320.Position - p113).Magnitude > 35 then
          return true, "teleported"
        end

        if p112 and p112.Parent and tick() - v316 > 0.75 then
          triggerTargetPart(p112)
          v316 = tick()
        end

        task.wait(0.15)
      end

      return false, "touch_not_confirmed"
    end

    function runObbyBoost()
      local v321 = getObbyPart()

      if not v321 then
        setWorldStatus("Waiting", "ObbyBlessing not found")
        return false
      else
        autoWalk.currentTask = "obby"
        autoWalk.currentTarget = v321

        setWorldStatus("Obby", "Pathing to boost")

        local v322, v323 = moveWithPathfinding(v321.Position, {
          Target = v321,
          TaskName = "obby",
        })

        if v322 then
          local v324, v325, v326 = getCharacterMovementParts()
          local position6 = v326 and v326.Position or v321.Position
          triggerTargetPart(v321)
          setWorldStatus("Obby", "Waiting for teleport")
          local v327
          v322, v327 = waitForObbyTeleport(v321, position6)

          if v322 then
            autoWalk.lastObbyAt = tick()
            setWorldStatus("Idle", "Obby boost collected")
            notify("- Auto Obby Luck Boost collected -", Color3.fromRGB(255, 220, 100))
            logWorld("Obby Luck Boost collected after teleport", "SUCCESS")

            if addLogConsole then
              addLogConsole:Log("Auto Obby Luck Boost collected", "SUCCESS")
            end
          else
            setWorldStatus("Waiting", "Obby touch not confirmed")
            logWorld("Obby touch did not teleport: " .. tostring(v327), "WARN")
          end
        else
          setWorldStatus("Waiting", "Obby failed: " .. tostring(v323))
          logWorld("Obby path failed: " .. tostring(v323), "WARN")
        end

        autoWalk.currentTask = nil
        autoWalk.currentTarget = nil

        clearTargetHighlight()
        return v322
      end
    end

    v65 = 0

    function runCloverCollect()
      rebuildCloverQueue()
      local v328 = table.remove(autoWalk.cloverQueue, 1)
      autoWalk.queueCount = #autoWalk.cloverQueue
      local v329 = not v328
      updateWorldAutomationMetrics()

      if v329 or not v328.model.Parent or not v328.hitox.Parent then
        setWorldStatus("Scanning", "No clovers in range")
        return false
      else
        autoWalk.currentTask = "clover"
        autoWalk.currentTarget = v328.model

        setWorldStatus("Clover", "Pathing to Hitox")

        local v330, v331 = moveWithPathfinding(v328.hitox.Position, {
          Target = v328.model,
          TaskName = "clover",
        })

        if v330 then
          triggerTargetPart(v328.hitox)
          local v332, v333 = waitForCloverGone(v328.model, v328.hitox)

          if v332 then
            autoWalk.cloverFailures[v328.model] = nil
            setWorldStatus("Scanning", "Clover collected")
            local v334 = tick()

            if v334 - v65 > 2 then
              v65 = v334
              notify("- Clover collected -", Color3.fromRGB(120, 255, 140))
            end

            logWorld("Clover collected", "SUCCESS")

            if addLogConsole then
              addLogConsole:Log("Clover collected", "SUCCESS")
            end
          else
            v331 = v333
            v330 = false
            setWorldStatus("Scanning", "Clover not collected")
            logWorld("Clover not collected yet: " .. tostring(v333), "WARN")
          end
        elseif v331 ~= "preempted" then
          if v331 == "no_path" or v331 == "blocked" or v331 == "stuck" then
            autoWalk.cloverFailures[v328.model] = (autoWalk.cloverFailures[v328.model] or 0) + 1

            if autoWalk.cloverFailures[v328.model] >= 2 then
              blacklistClover(v328.model, 30)
              autoWalk.cloverFailures[v328.model] = nil
            end
          end

          setWorldStatus("Scanning", "Clover failed: " .. tostring(v331))
          logWorld("Clover failed: " .. tostring(v331), "WARN")

          if addLogConsole then
            addLogConsole:Log("Clover failed: " .. tostring(v331), "WARN")
          end
        else
          setWorldStatus("Obby", "Clover paused for obby")
        end

        autoWalk.currentTask = nil
        autoWalk.currentTarget = nil

        clearTargetHighlight()
        return v330, v331
      end
    end

    function autoMerchantRulesFor(p114)
      local v335 = {}

      for index62, value51 in ipairs(ensureAutoMerchantConfig().Rules) do
        if type(value51) == "table" and value51.Merchant == p114 and value51.Item
          and value51.Item ~= "" then
          v335[#v335 + 1] = {
            Merchant = p114,
            Item = tostring(value51.Item),
            Amount = math.max(1, math.floor(tonumber(value51.Amount) or 1)),
            Max = value51.Max == true,
          }
        end
      end

      return v335
    end

    function findAutoMerchantTarget()
      if not ensureAutoMerchantConfig().Enabled then
        return nil
      else
        local v336, v337, v338 = getCharacterMovementParts()
        local huge4 = math.huge
        local v339 = nil

        for index63, value52 in ipairs(scanMerchantModels()) do
          local v340 = autoMerchant.failures[value52.Model]

          if value52.Model and value52.Model.Parent and not autoMerchant.handled[value52.Model]
            and (not v340 or tick() >= v340) then
            local v341 = autoMerchantRulesFor(value52.Name)

            if #v341 > 0 then
              local magnitude10 = v338 and (v338.Position - value52.Position).Magnitude or 0

              if magnitude10 < huge4 then
                value52.Rules = v341
                huge4 = magnitude10
                v339 = value52
              end
            end
          end
        end

        return v339
      end
    end

    function merchantChoiceMatcher(p115)
      local gsub2 = normalizeUIText(p115):gsub("%[", ""):gsub("%]", ""):gsub("%s+", "")

      return function(p116)
        return tostring(p116 or ""):gsub("%[", ""):gsub("%]", ""):gsub("%s+", "") == gsub2
      end
    end

    function activateMerchantDialog(p117, p118)
      local v342 = p117 == "Rin" and "Shop" or "Open"
      local v343 = tick()
      local v344 = 0
      local v345 = 0
      local v346 = 0

      while userConfig.AutoMerchant and userConfig.AutoMerchant.Enabled and autoMerchant.running and p118
        and p118.Parent and tick() - v343 < 18 do
        if inputHelper.waitMerchantShopRefs(0.08) then
          return true, "shop_opened"
        else
          local v347, v348, v349 = getCharacterMovementParts()

          if not v348 or not v349 or v348.Health <= 0 then
            return false, "no_character"
          else
            local v350 = getModelPosition(p118)

            if not v350 then
              return false, "merchant_position_missing"
            else
              if tick() - v344 > 0.4 then
                inputHelper.setLookAtCamera(v349, v350, 22)
                v344 = tick()
              end

              if tick() - v345 > 0.25 then
                inputHelper.activateNearbyPrompts(v349.Position, 45)
                inputHelper.pressKey(Enum.KeyCode.E, 0.05)
                v345 = tick()
              end

              local v351 = inputHelper.findDialogChoice(v342, merchantChoiceMatcher(v342))

              if v351 and tick() - v346 > 0.65 then
                setWorldStatus("Merchant", "Clicking " .. v342)

                if inputHelper.activateGuiObject(v351, nil, 5) then
                  v346 = tick()

                  if inputHelper.waitMerchantShopRefs(2.25) then
                    return true, "shop_opened"
                  end
                end
              end

              task.wait(0.08)
            end
          end
        end
      end

      if not userConfig.AutoMerchant or not userConfig.AutoMerchant.Enabled then
        return false, "disabled"
      end

      return false, "shop_open_timeout"
    end

    function waitMerchantNearAfterTeleport(p119, p120)
      local v352 = tick()

      while tick() - v352 < 8 do
        local v353, v354, v355 = getCharacterMovementParts()
        local v356 = nil
        local huge5 = math.huge

        for index64, value53 in ipairs(scanMerchantModels()) do
          if value53.Name == p119 and value53.Model and value53.Model.Parent then
            local magnitude11 = v355 and (v355.Position - value53.Position).Magnitude or 0

            if magnitude11 < huge5 then
              v356 = value53
              huge5 = magnitude11
            end
          end
        end

        if v356 and (not v355 or huge5 <= 80 or v356.Model == p120) then
          return v356
        end

        task.wait(0.25)
      end

      return p120 and p120.Parent and {
        Name = p119,
        Model = p120,
        Position = getMerchantPathPosition(p120) or getModelPosition(p120),
      } or nil
    end

    function waitScriptSplashForAutomation(p121, p122)
      local v357 = tick()

      while ui and ui._bootSplash and tick() - v357 < (p122 or 8) do
        setWorldStatus(p121 or "Automation", "Waiting for UI")
        task.wait(0.2)
      end
    end

    function useMerchantTeleportItem()
      local v358 = { "Merchant teleporter", "Merchant Teleport" }
      local v359 = "not_attempted"
      local v360 = inputHelper.openInventory()

      if not v360 or not v360.Search then
        inputHelper.closeInventory()
        return false, "inventory_ui_missing"
      else
        v360.Search.Text = "Merchant"
        task.wait(0.25)
        local v361 = inputHelper.resolveInventoryRefs()
        local v362 = false

        for index65, value54 in ipairs(v358) do
          if inputHelper.findInventoryItemExact(value54, v361) or inputHelper.findInventoryItem(value54, v361) then
            v362 = true
            break
          end
        end

        inputHelper.closeInventory()

        if not v362 then
          return false, "item_not_found"
        end

        task.wait(0.2)

        for i11 = 1, 3 do
          if not userConfig.AutoMerchant or not userConfig.AutoMerchant.Enabled or not autoMerchant.running then
            return false, "disabled"
          end

          setWorldStatus("Merchant", "Using teleport " .. tostring(i11) .. "/3")

          for index66, value55 in ipairs(v358) do
            local v363, v364 = inputHelper.useInventoryItemExact(value55, 1, {
              NotifyFailure = false,
              Attempts = 1,
              CloseAfter = true,
            })

            v359 = v364 or v359

            if v363 then
              return true, "used_" .. value55
            end

            task.wait(0.15)
          end

          if i11 < 3 then
            task.wait(0.45)
          end
        end

        return false, v359
      end
    end

    function isAutoPopPaused(p123)
      if not p123 then
        return false
      end

      return p123.isUsingSCBR or p123.isSelling or (p123._autoPopPausers or 0) > 0
    end

    function acquireAutoPopPause(index67)
      if not index67 then
        return
      end

      index67._autoPopPausers = (index67._autoPopPausers or 0) + 1
    end

    function releaseAutoPopPause(p124)
      if not p124 then
        return
      end

      p124._autoPopPausers = math.max(0, (p124._autoPopPausers or 1) - 1)
    end

    function runAutoMerchant(p125)
      if autoMerchant.running then
        return false, "already_running"
      end

      local v365, v366

      if not p125 or not p125.Model or not p125.Model.Parent then
        return false, "merchant_missing"
      else
        local rules = p125.Rules or autoMerchantRulesFor(p125.Name)

        if #rules == 0 then
          return false, "no_rules"
        else
          autoMerchant.running = true
          autoMerchant.busy = true

          autoWalk.currentTask = "merchant"
          autoWalk.currentTarget = p125.Model

          local v367 = rawget(_G, "__AF")

          if v367 then
            local total2 = 0

            while isAutoPopPaused(v367) and total2 < 60 and userConfig.AutoMerchant
              and userConfig.AutoMerchant.Enabled do
              setWorldStatus("Merchant", "Waiting for UI")
              task.wait(0.5)
              total2 = total2 + 0.5
            end

            acquireAutoPopPause(v367)
          end

          setWorldStatus("Merchant", "Going to " .. tostring(p125.Name))
          logWorld("Auto Merchant started: " .. tostring(p125.Name), "WARN")
          waitScriptSplashForAutomation("Merchant", 8)
          local v368 = false

          if useMerchantTeleportItem() then
            v368 = true
            setWorldStatus("Merchant", "Merchant teleporter used")
            task.wait(2.5)
            local v369 = waitMerchantNearAfterTeleport(p125.Name, p125.Model)

            if v369 and v369.Model then
              p125.Model = v369.Model

              p125.Position = getMerchantPathPosition(v369.Model) or v369.Position
                or getModelPosition(v369.Model)

              autoWalk.currentTarget = p125.Model
            end
          end

          if userConfig.AutoMerchant and userConfig.AutoMerchant.Enabled and p125.Model and p125.Model.Parent then
            if not v368 then
              p125.Position = getMerchantPathPosition(p125.Model)

              if p125.Position then
                v366, v365 = moveWithPathfinding(p125.Position, {
                  Target = p125.Model,
                  TaskName = "merchant",
                  IsActive = function()
                    return userConfig.AutoMerchant and userConfig.AutoMerchant.Enabled and autoMerchant.running
                      and p125.Model and p125.Model.Parent
                  end,
                })
              else
                v366 = false
                v365 = "merchant_position_missing"
              end
            else
              v366 = true
              v365 = "teleported"
            end
          else
            v365 = "merchant_gone"
            v366 = false
          end

          if v366 and userConfig.AutoMerchant and userConfig.AutoMerchant.Enabled and p125.Model
            and p125.Model.Parent then
            setWorldStatus("Merchant", "Opening shop")
            v366, v365 = activateMerchantDialog(p125.Name, p125.Model)
          end

          if v366 and userConfig.AutoMerchant and userConfig.AutoMerchant.Enabled then
            local v370 = inputHelper.waitMerchantShopRefs(14)

            if not v370 or not v370.ScrollingFrame then
              v366 = false
              v365 = "shop_ui_missing"
            else
              for index68, value56 in ipairs(rules) do
                if not userConfig.AutoMerchant.Enabled or not p125.Model or not p125.Model.Parent then
                  v366 = false
                  v365 = "disabled_or_merchant_gone"
                  break
                else
                  setWorldStatus("Merchant", "Buying " .. tostring(value56.Item))

                  local v371, v372 = inputHelper.buyMerchantItem(
                    value56.Item, value56.Amount, value56.Max, 4
                  )

                  if not v371 and v372 ~= "item_unavailable" then
                    logWorld("Merchant buy failed: " .. tostring(value56.Item) .. " - "
                      .. tostring(v372), "WARN")
                  end

                  task.wait(0.25)
                end
              end

              if v366 then
                v365 = "completed"
              end
            end
          end

          pcall(function() inputHelper.closeMerchantShop() end)
          inputHelper.restoreCamera()
          clearTargetHighlight()

          autoWalk.currentTask = nil
          autoWalk.currentTarget = nil

          autoMerchant.running = false
          autoMerchant.busy = false

          if v367 then
            releaseAutoPopPause(v367)
          end

          if p125.Model then
            if v366 then
              autoMerchant.handled[p125.Model] = true
              autoMerchant.failures[p125.Model] = nil
            else
              autoMerchant.failures[p125.Model] = tick() + 20
            end
          end

          if v366 then
            notify(
              "- Auto Merchant: " .. tostring(p125.Name) .. " completed -",
              Color3.fromRGB(120, 255, 180)
            )

            setWorldStatus("Idle", "Merchant completed")
            logWorld("Auto Merchant completed: " .. tostring(p125.Name), "SUCCESS")

            if addLogConsole then
              addLogConsole:Log("Auto Merchant completed: " .. tostring(p125.Name), "SUCCESS")
            end
          else
            setWorldStatus("Waiting", "Merchant failed: " .. tostring(v365))
            logWorld("Auto Merchant failed: " .. tostring(v365), "WARN")

            if addLogConsole then
              addLogConsole:Log("Auto Merchant failed: " .. tostring(v365), "WARN")
            end
          end

          return v366, v365
        end
      end
    end

    function signalEdenSpawn(p126)
      v63.pending = true
      v63.pendingAt = tick()
      v63.lastSignalText = tostring(p126 or "")

      if userConfig.AutoContractWithEden then
        setWorldStatus("Eden", "Spawn detected")
        logWorld("Eden spawn signal detected", "WARN")
      end
    end

    function getCurrentBiomeFromGuiTextRaw()
      local mainInterface3 = playerGui:FindFirstChild("MainInterface")
      local v373

      if mainInterface3 then
        for index69, value57 in ipairs(mainInterface3:GetDescendants()) do
          if value57:IsA("TextLabel") then
            local sS2 = tostring(value57.Text or ""):match("%[%s*(.-)%s*%]")

            if sS2 and sS2 ~= "" then
              local gsub3 = sS2:upper():gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")

              if gsub3 == "THE LIMBO" then
                return gsub3
              end

              v373 = v373 or gsub3
            end
          end
        end

        return v373
      end

      return v373
    end

    getCurrentBiomeFromGuiText = GYESG.memoBiome(getCurrentBiomeFromGuiTextRaw)

    function isInLimbo()
      return getCurrentBiomeFromGuiText() == "THE LIMBO"
    end

    function getLimboStateReason()
      local v374 = getCurrentBiomeFromGuiText()

      if v374 == "THE LIMBO" then
        return true, "current_biome_limbo"
      end

      if v374 then
        return false, "current_biome_" .. v374
      end

      return false
    end

    function createLimboEdenBridges()
      clearTempBridges()

      for index70, value58 in ipairs({
        {
          Vector3.new(-10037.662109, -2.500069, 35.459698),
          Vector3.new(-10023.973633, -6.500064, 25.189411),
        },
        {
          Vector3.new(-10023.973633, -6.500064, 25.189411),
          Vector3.new(-10008.220703, -2.50006, 11.835706),
        },
        {
          Vector3.new(-10003.583008, -2.50006, -17.489046),
          Vector3.new(-10057.149414, 9.500052, -80.573837),
        },
        {
          Vector3.new(-10041.933594, 9.500052, -99.13121),
          Vector3.new(-10037.21582, 12.500055, -98.421524),
        },
        {
          Vector3.new(-10037.21582, 12.500055, -98.421524),
          Vector3.new(-9982.576172, 24.499943, -98.291801),
        },
      }) do
        local v375 = value58[2]
        local v376 = value58[1]
        local magnitude12 = (v375 - v376).Magnitude

        if magnitude12 > 0.5 then
          local part4 = Instance.new("Part")
          part4.Name = "BiomeMacroEdenLimboBridge_" .. index70
          part4.Anchored = true
          part4.CanCollide = true
          part4.CanTouch = false
          part4.Material = Enum.Material.SmoothPlastic
          part4.Color = Color3.fromRGB(120, 160, 255)
          part4.Transparency = userConfig.PathDebug and 0.72 or 1
          part4.Size = Vector3.new(8, 0.45, magnitude12 + 3)
          part4.CFrame = CFrame.lookAt(v376:Lerp(v375, 0.5), v375)
          part4.Parent = workspace

          autoWalk.bridgeParts[#autoWalk.bridgeParts + 1] = part4
        end
      end

      return #autoWalk.bridgeParts > 0
    end

    function enterLimboForEden()
      local v377, v378 = getLimboStateReason()

      if v377 then
        return true, "already_limbo"
      else
        logWorld("Eden Limbo check: " .. tostring(v378 or "no_current_biome_text"), "INFO")
        local v379 = "portable_crack_not_used"

        for i12 = 1, 3 do
          if not userConfig.AutoContractWithEden then
            return false, "disabled"
          else
            setWorldStatus("Eden", "Using Portable Crack")

            local v380, v381 = inputHelper.useInventoryItem("Portable Crack", 1, {
              NotifyFailure = false,
              Attempts = 3,
            })

            v379 = v381 or v379

            logWorld(
              string.format("Portable Crack attempt %d: %s", i12, tostring(v381 or v380)),
              v380 and "INFO" or "WARN"
            )

            local v382 = tick()

            while userConfig.AutoContractWithEden and tick() - v382 < 35 do
              if isInLimbo() then
                task.wait(3)
                return true, "entered_limbo"
              end

              task.wait(0.5)
            end

            task.wait(1)
          end
        end

        return false, "limbo_timeout_" .. tostring(v379)
      end
    end

    function tryContractEdenAtPosition(p127)
      local v383 = tick()
      local v384 = 0
      local v385 = 0

      while userConfig.AutoContractWithEden and tick() - v383 < 180 do
        local v386, v387, v388 = getCharacterMovementParts()

        if not v387 or not v388 or v387.Health <= 0 then
          return false, "no_character"
        elseif (v388.Position - p127).Magnitude > 35 then
          return false, "moved_from_eden_spot"
        else
          if tick() - v385 > 0.35 then
            inputHelper.setLookDownCamera(v388, 85)
            v385 = tick()
          end

          if tick() - v384 > 0.25 then
            inputHelper.pressKey(Enum.KeyCode.E, 0.08)
            inputHelper.activateNearbyPrompts(v388.Position, 55)
            v384 = tick()
          end

          local contractWithIt = inputHelper.findDialogChoice("Contract with it")

          if contractWithIt and inputHelper.activateGuiObject(contractWithIt, nil, 4) then
            return true, "contracted"
          end

          task.wait(0.05)
        end
      end

      if not userConfig.AutoContractWithEden then
        return false, "disabled"
      end

      return false, "contract_timeout"
    end

    function runEdenContract()
      if v63.running then
        return false, "already_running"
      else
        v63.running = true

        autoWalk.currentTask = "eden"
        autoWalk.currentTarget = nil

        local vector4 = Vector3.new(-9919.524414, 24.499947, -105.144455)
        setWorldStatus("Eden", "Starting contract")
        logWorld("Auto Contract with Eden started", "WARN")
        local v389, v390 = enterLimboForEden()

        if v389 then
          local v391, v392, v393 = getCharacterMovementParts()

          if v393 and (v393.Position - vector4).Magnitude > 1000 then
            v389 = false
            v390 = "eden_too_far_after_limbo"
          end
        end

        if v389 then
          setWorldStatus("Eden", "Pathing in Limbo")
          createLimboEdenBridges()

          v389, v390 = moveWithPathfinding(vector4, {
            TaskName = "eden",
            IsActive = function() return userConfig.AutoContractWithEden and v63.running end,
          })
        end

        if v389 then
          setWorldStatus("Eden", "Trying prompts")
          v389, v390 = tryContractEdenAtPosition(vector4)
        end

        inputHelper.restoreCamera()
        clearTempBridges()
        clearTargetHighlight()

        autoWalk.currentTask = nil
        autoWalk.currentTarget = nil

        v63.running = false

        autoMerchant.running = false
        autoMerchant.busy = false

        v63.pending = false

        if v389 then
          v63.lastContractAt = tick()
          userConfig.AutoContractWithEden = false
          SaveDataDebounced()
          updateWorldAutomationMetrics()

          if addToggle3 then
            pcall(function() addToggle3:Set(false) end)
          end

          notify("- Contracted with Eden -", Color3.fromRGB(160, 190, 255))
          setWorldStatus("Idle", "Contracted with Eden")
          logWorld("Contracted with Eden", "SUCCESS")

          if addLogConsole then
            addLogConsole:Log("Contracted with Eden", "SUCCESS")
          end
        else
          setWorldStatus("Waiting", "Eden failed: " .. tostring(v390))
          logWorld("Eden contract failed: " .. tostring(v390), "WARN")

          if addLogConsole then
            addLogConsole:Log("Eden contract failed: " .. tostring(v390), "WARN")
          end
        end

        return v389, v390
      end
    end

    function automationEnabled()
      return userConfig.AutoObbyLuckBoost or userConfig.AutoCollectClover or userConfig.AutoContractWithEden
        or userConfig.AutoMerchant and userConfig.AutoMerchant.Enabled
    end

    function startAutomationLoop()
      if autoWalk.enabled then
        return
      end

      autoWalk.enabled = true
      autoWalk.runId = autoWalk.runId + 1

      local runId = autoWalk.runId
      autoWalk.lastObbyAt = autoWalk.lastObbyAt > 0 and autoWalk.lastObbyAt or tick() - 120
      setWorldStatus("Starting", "World automation enabled")
      logWorld("World automation loop started", "INFO")

      task.spawn(function()
        while autoWalk.enabled and autoWalk.runId == runId do
          if not automationEnabled() then
            setWorldStatus("Idle", "No world automation enabled")
            task.wait(0.7)
          else
            if v63.pending and v63.pendingAt > 0 and tick() - v63.pendingAt > 1800 then
              v63.pending = false
              setWorldStatus("Waiting", "Eden signal expired")
            end

            if userConfig.AutoContractWithEden and v63.pending then
              local v394 = runEdenContract()
              task.wait(v394 and 0.5 or 1)
            else
              if userConfig.AutoContractWithEden and not v63.pending then
                setWorldStatus("Waiting", "Eden spawn")
              end

              if v18 then
                setWorldStatus("Paused", "The Limbo")
                task.wait(0.7)
              else
                local v395 = false
                local v396 = findAutoMerchantTarget()

                if v396 then
                  v395 = runAutoMerchant(v396)
                elseif userConfig.AutoObbyLuckBoost and tick() - autoWalk.lastObbyAt >= 120 then
                  v395 = runObbyBoost()
                elseif userConfig.AutoCollectClover then
                  local v397, v398 = runCloverCollect()
                  v395 = v397 or v398 == "preempted"
                elseif userConfig.AutoObbyLuckBoost then
                  setWorldStatus("Waiting", "Obby timer")
                elseif userConfig.AutoContractWithEden then
                  setWorldStatus("Waiting", "Eden spawn")
                end

                task.wait(v395 and 0.25 or 1)
              end
            end
          end
        end

        setWorldStatus("Idle", "Loop stopped")
      end)
    end

    function stopAutomationLoopIfIdle()
      if automationEnabled() then
        return
      end

      autoWalk.enabled = false
      autoWalk.runId = 0
      autoWalk.currentTask = nil
      autoWalk.currentTarget = nil

      clearTempBridges()
      clearPathDebug(false)
      setWorldStatus("Idle", "World automation off")
      logWorld("World automation loop stopped", "INFO")
    end

    function cancelActivePathVisuals(p128)
      clearTempBridges()
      clearPathDebug(false)
      clearTargetHighlight()
      setWorldStatus("Idle", p128 or "Path cancelled")
    end

    v22[#v22 + 1] = function()
      autoWalk.enabled = false
      autoWalk.runId = 0

      v63.running = false

      autoMerchant.running = false
      autoMerchant.busy = false

      clearTempBridges()
      clearPathDebug(false)
    end

    bootStep("Building status dashboard", 0.46, "status page")

    ui:AddSectionHeader(2, "Status", "Live state of your current macro session")
    ui:AddDivider(2, "State")

    addStatusBadge2 = ui:AddStatusBadge2(2, "Macro State", "offline")
    ui:AddDivider(2, "Session Timer")

    local addMetricRow = ui:AddMetricRow(2, {
      { Label = "Elapsed Time", Value = "00:00:00", Unit = "hh:mm:ss" },
      { Label = "Last Biome", Value = "None", Unit = "" },
    })

    v49 = addMetricRow[1]
    v52 = addMetricRow[2]
    ui:AddDivider(2, "Session Counts")

    local addMetricRow2 = ui:AddMetricRow(2, {
      { Label = "Biomes Detected", Value = "0", Unit = "this session" },
      { Label = "Merchants Found", Value = "0", Unit = "this session" },
    })

    v50 = addMetricRow2[1]
    v51 = addMetricRow2[2]
    ui:AddDivider(2, "Event Log")

    addLogConsole = ui:AddLogConsole(2, 200)
    addLogConsole:Log("Waiting for macro to start", "INFO")

    ui:AddSectionHeader(4, "Statistics", "Lifetime biome detection across all sessions")
    ui:AddDivider(4, "All-Time")

    v53 = ui:AddMetricRow(4, {
      {
        Label = "Total Biomes",
        Value = tostring(globalStats.TotalBiomes),
        Unit = "all sessions",
      },
    })[1]

    ui:AddDivider(4, "Rare Biome Counters")

    local addMetricRow3 = ui:AddMetricRow(4, {
      {
        Label = "Glitched",
        Value = tostring(globalStats.BiomeDetails.GLITCHED or 0),
        Unit = "found",
      },
      {
        Label = "Dreamspace",
        Value = tostring(globalStats.BiomeDetails.DREAMSPACE or 0),
        Unit = "found",
      },
      {
        Label = "Cyberspace",
        Value = tostring(globalStats.BiomeDetails.CYBERSPACE or 0),
        Unit = "found",
      },
    })

    v54.GLITCHED = addMetricRow3[1]
    v54.DREAMSPACE = addMetricRow3[2]
    v54.CYBERSPACE = addMetricRow3[3]

    v54.SINGULARITY = ui:AddMetricRow(4, {
      {
        Label = "Singularity",
        Value = tostring(globalStats.BiomeDetails.SINGULARITY or 0),
        Unit = "found",
      },
    })[1]

    v54["THE RADIANT FOREST"] = ui:AddMetricRow(4, {
      {
        Label = "Radiant Forest",
        Value = tostring(globalStats.BiomeDetails["THE RADIANT FOREST"] or 0),
        Unit = "found",
      },
    })[1]

    ui:AddDivider(4, "Per Biome")
    local v399 = {}

    for index71, value59 in ipairs({
      "NULL", "CORRUPTION", "STARFALL", "HEAVEN", "HELL", "SAND STORM", "WINDY", "RAINY",
      "SNOWY", "LOST FOREST",
    }) do
      if not isBiomeInactive(value59) then
        table.insert(v399, value59)
      end
    end

    for i13 = 1, #v399, 3 do
      local v400 = {}

      for i14 = i13, math.min(i13 + 3 - 1, #v399) do
        local v401 = v399[i14]

        if not globalStats.BiomeDetails[v401] then
          globalStats.BiomeDetails[v401] = 0
        end

        table.insert(v400, {
          Label = v401,
          Value = tostring(globalStats.BiomeDetails[v401]),
          Unit = "detected",
        })
      end

      for index72, value60 in ipairs((ui:AddMetricRow(4, v400))) do
        local v402 = v399[i13 + index72 - 1]

        if v402 then
          v54[v402] = value60
        end
      end
    end

    bootStep("Registering notification controls", 0.6, "pings page")

    ui:AddSectionHeader(5, "Pings", "Notifications, pings, and identification")
    ui:AddDivider(5, "Global Ping IDs")

    addInput3 = ui:AddInput(5, "User IDs to Ping", "ID1, ID2... (numbers only)", function(discordId)
      userConfig.DiscordId = discordId
      SaveData()
    end)

    addInput4 = nil

    addInput4 = ui:AddInput(5, "Role IDs to Ping", "Role1, Role2... (numbers only)", function(roleId)
      userConfig.RoleId = roleId
      SaveData()
    end)

    ui:AddLabel(
      5,
      "These IDs are used as the default for every toggle below. Leave a toggle's custom field empty to use these globals.",
      "muted"
    )

    ui:AddDivider(5, "Ping Threshold")

    addInputNumber = ui:AddInputNumber(5, "Aura Rarity Ping Threshold", {
      Min = 0,
      Max = 9999999999,
      Placeholder = "e.g. 999000000",
    }, function(pingThreshold)
      userConfig.PingThreshold = pingThreshold
      SaveData()
    end)

    function addPingToggle(p129, key6, p130, p131, p132)
      local v403 = p132
      v403 = v403 or function(p133) end

      local addInput5, addLabel, addLabel2

      local addToggle4 = ui:AddToggle(p129, p130, p131, function(p134)
        v403(p134)
        SaveData()

        if p134 then
          pcall(function() addLabel2.Frame.Visible = true end)
          pcall(function() addInput5.Frame.Visible = true end)
          pcall(function() addLabel.Frame.Visible = true end)
        else
          pcall(function() addLabel2.Frame.Visible = false end)
          pcall(function() addInput5.Frame.Visible = false end)
          pcall(function() addLabel.Frame.Visible = false end)
        end
      end)

      addLabel2 = ui:AddLabel(p129, "  -> Specific IDs for this event", "muted")

      addInput5 = ui:AddInput(p129, nil, "user1, r:role1, r:role2...", function(p135)
        if not userConfig.CustomPingIds then
          userConfig.CustomPingIds = {}
        end

        userConfig.CustomPingIds[key6] = p135
        SaveData()
      end)

      addLabel = ui:AddLabel(
        p129, "  Numbers = user IDs * r:prefix = role IDs * Empty = uses global IDs above",
        "muted"
      )

      if not p131 then
        pcall(function() addLabel2.Frame.Visible = false end)
        pcall(function() addInput5.Frame.Visible = false end)
        pcall(function() addLabel.Frame.Visible = false end)
      end

      task.defer(function()
        if not p131 then
          pcall(function() addLabel2.Frame.Visible = false end)
          pcall(function() addInput5.Frame.Visible = false end)
          pcall(function() addLabel.Frame.Visible = false end)
        end
      end)

      local v404 = {
        Toggle = addToggle4,
        Input = addInput5,
        Label = addLabel,
        Title = addLabel2,
      }

      v60[key6] = v404
      return v404
    end

    ui:AddDivider(5, "Biome Pings")

    ui:AddAlert(
      5, "How Pings work",
      "The User/Role IDs above ping for **every** active toggle by default. To ping **only specific people** for a single event, activate its toggle and fill in the custom IDs field that appears below it. DREAMSPACE, GLITCHED and CYBERSPACE always ping @everyone and are not listed here.",
      "info"
    )

    local v405 = {}

    for key7, value61 in pairs(v40) do
      local v406 = false

      for index73, value62 in ipairs(v41) do
        if key7 == value62 then
          v406 = true
          break
        end
      end

      if userConfig.PingBiomes[key7] == nil then
        userConfig.PingBiomes[key7] = false
      end

      if not v406 and not isBiomeInactive(key7) then
        table.insert(v405, key7)
      end
    end

    table.sort(v405)

    for index74, value63 in ipairs(v405) do
      local v407 = value63

      v57[v407] = addPingToggle(
        5, v407, "Ping on " .. v407, userConfig.PingBiomes[v407],
        function(p136) userConfig.PingBiomes[v407] = p136 end
      )
    end

    ui:AddDivider(5, "Merchant Pings")

    for index75, value64 in ipairs(v42) do
      local v408 = value64

      if userConfig.PingMerchants[v408] == nil then
        userConfig.PingMerchants[v408] = false
      end

      v58[v408] = addPingToggle(
        5, v408, "Ping on " .. v408, userConfig.PingMerchants[v408],
        function(p137) userConfig.PingMerchants[v408] = p137 end
      )
    end

    ui:AddDivider(5, "Special Events")

    v59 = addPingToggle(5, "Eden", "Ping on Eden spawn", userConfig.PingEden, function(pingEden)
      userConfig.PingEden = pingEden
    end)

    task.spawn(function()
      task.wait(0.6)

      if addInput then
        pcall(function() addInput:Set("") end)
      end

      if addInput2 and userConfig.PSLink ~= "" then
        pcall(function() addInput2:Set(smartShorten(userConfig.PSLink)) end)
      end

      if addInput3 and userConfig.DiscordId ~= "" then
        pcall(function() addInput3:Set(userConfig.DiscordId) end)
      end

      if addInput4 and userConfig.RoleId ~= "" then
        pcall(function() addInput4:Set(userConfig.RoleId) end)
      end

      if addInputNumber and userConfig.PingThreshold ~= 999999999 then
        pcall(function() addInputNumber:Set(userConfig.PingThreshold) end)
      end

      if addToggle then
        pcall(function() addToggle:Set(userConfig.AntiAfk) end)
      end

      for key8, value65 in pairs(v57) do
        local v409 = key8
        local v410 = value65

        if userConfig.PingBiomes[v409] ~= nil then
          pcall(function() v410.Toggle:Set(userConfig.PingBiomes[v409]) end)
        end
      end

      for key9, value66 in pairs(v58) do
        local v411 = key9
        local v412 = value66

        if userConfig.PingMerchants[v411] ~= nil then
          pcall(function() v412.Toggle:Set(userConfig.PingMerchants[v411]) end)
        end
      end

      if v59 then
        pcall(function() v59.Toggle:Set(userConfig.PingEden) end)
      end

      for key10, value67 in pairs(v60) do
        local v413 = value67

        if v413.Toggle:Get() then
          pcall(function() v413.Title.Frame.Visible = true end)
          pcall(function() v413.Input.Frame.Visible = true end)
          pcall(function() v413.Label.Frame.Visible = true end)
        else
          pcall(function()
            if v413.Title and v413.Title.Frame then
              v413.Title.Frame.Visible = false
            end
          end)

          pcall(function() v413.Input.Frame.Visible = false end)
          pcall(function() v413.Label.Frame.Visible = false end)
        end

        local customPingIds = userConfig.CustomPingIds and userConfig.CustomPingIds[key10]

        if customPingIds and customPingIds ~= "" then
          pcall(function() v413.Input:Set(customPingIds) end)
        end
      end

      if addInputNumber2 then
        pcall(function() addInputNumber2:Set(userConfig.BiomeScanInterval or 0.5) end)
      end

      if addInputNumber3 then
        pcall(function() addInputNumber3:Set(userConfig.AntiAfkInterval or 300) end)
      end

      if addToggle2 then
        pcall(function() addToggle2:Set(userConfig.PathDebug) end)
      end

      if addMultiSelect then
        pcall(function()
          local v414 = {}

          for key11, value68 in pairs(userConfig.MutedBiomes or {}) do
            if value68 then
              v414[#v414 + 1] = key11
            end
          end

          table.sort(v414)
          addMultiSelect:Set(v414)
        end)
      end

      if addInputNumber4 then
        pcall(function() addInputNumber4:Set(userConfig.AutoFishTarget or 20) end)
      end

      if addInputNumber5 then
        pcall(function() addInputNumber5:Set(userConfig.AutoFishSCBRMins or 5) end)
      end
    end)

    v66 = true
    ui:OnDestroy(function() v66 = false end)

    task.spawn(function()
      while v66 do
        task.wait(1)

        if macroRunning and v12.StartTick > 0 then
          local v415 = math.max(0, os.time() - v12.StartTick)

          local v416 = string.format(
            "%02d:%02d:%02d", math.floor(v415 / 3600), math.floor(v415 % 3600 / 60),
            math.floor(v415 % 60)
          )

          if v49 then
            ui:SetMetricValue(v49, v416)
          end
        end

        if v50 then
          ui:SetMetricValue(v50, v12.BiomeCount)
        end

        if v51 then
          ui:SetMetricValue(v51, v12.MerchantCount)
        end

        if v53 then
          ui:SetMetricValue(v53, globalStats.TotalBiomes)
        end

        if v52 then
          if name and v13 then
            ui:SetMetricValue(v52, name .. " (" .. formatElapsed(os.time() - v13) .. " ago)")
          else
            ui:SetMetricValue(v52, "None")
          end
        end

        for key12, value69 in pairs(v54) do
          ui:SetMetricValue(value69, tostring(globalStats.BiomeDetails[key12] or 0))
        end
      end
    end)

    function v35()
      local v417 = extractWebhooks(userConfig.Webhook)

      if #v417 == 0 then
        notify("- /test: No valid webhook configured -", Color3.fromRGB(193, 9, 9))
        return
      end

      notify("- /test: Testing Webhook... -", Color3.fromRGB(100, 180, 255))

      task.spawn(function()
        local v418 = syn and syn.request or request or http_request
          or function(p138) return httpService:PostAsync(p138.Url, p138.Body) end

        local v419 = os.time()
        local v420 = string.format("<t:%d:F> (<t:%d:R>)", v419, v419)
        local v421 = true

        local jsonEncode2 = httpService:JSONEncode({
          embeds = {
            {
              title = v420,
              description = "> # Webhook Working",
              color = 65416,
              footer = {
                text = "Slaoq's Biome Macro - " .. v39 .. " | Webhook Test",
                icon_url = "https://media.discordapp.net/attachments/1296977365150335049/1473317870292439103/8UXDknU.png?ex=6995c5b1&is=69947431&hm=d1daa8d58782b32484f96e01450048d8111325dba1143b6c8bd0f09964972860&animated=true",
              },
            },
          },
        })

        for index76, value70 in ipairs(v417) do
          local url = value70
          local v422 = false
          local v423 = ""

          for i15 = 1, 3 do
            local v424, v425 = pcall(function()
              return v418({
                Url = url,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = jsonEncode2,
              })
            end)

            if v424 and v425 then
              local statusCode3 = v425.StatusCode or 0

              if statusCode3 == 204 or statusCode3 == 200 then
                v422 = true
                break
              end

              if statusCode3 == 429 then
                v423 = "Rate Limited (429)"
                warn("[Webhook] Rate limited during startup webhook test, skipping retry")
                break
              end

              v423 = "Status " .. tostring(statusCode3)
              task.wait(0.5)
            else
              v423 = "Request failed"
              task.wait(1)
            end
          end

          if v422 then
            notify(
              string.format("- /test: Webhook %d working -", index76),
              Color3.fromRGB(100, 220, 100)
            )
          else
            v421 = false

            notify(
              string.format("- /test: Webhook %d NOT working (%s) -", index76, v423),
              Color3.fromRGB(193, 9, 9)
            )
          end
        end

        if #v417 > 1 and v421 then
          notify("- /test: All webhooks working -", Color3.fromRGB(100, 220, 100))
        end
      end)
    end

    function MainLogic()
      local displayName, name4, f14, f15, f16, f17, f18, f19, f20, f21, f22, f23, f24, f25, f26,
        f27, f28, f29, f30, f31, f32, f33, f34, v426, psLink, antiAfk2, v427, v428, f35, f36,
        f37, f38, v429, v430, v431, v432, f39, v433, v434, v435, v436, v437, f40, f41, f42,
        v438, v439, v440, f43, v441, v442, v443, jsonEncode3, f44, v444, v445, f45, v446

      if v34 then
        return
      else
        v34 = true
        v426 = "NORMAL"
        psLink = userConfig.PSLink
        local webhook = userConfig.Webhook
        local discordId2 = userConfig.DiscordId
        local pingThreshold2 = userConfig.PingThreshold
        antiAfk2 = userConfig.AntiAfk
        displayName = localPlayer and localPlayer.DisplayName or "Unknown"
        name4 = localPlayer and localPlayer.Name or "Unknown"
        v427 = "Slaoq's Biome Macro - " .. v39 .. ""
        v428 = 0

        function f35(p139)
          local v447 = math.floor(p139)

          return string.format(
            "%02d:%02d:%02d", math.floor(v447 / 3600), math.floor(v447 % 3600 / 60), v447 % 60
          )
        end

        function f36(p140)
          return string.format("<t:%d:F> (<t:%d:R>)", p140, p140)
        end

        function f37()
          return v427 .. " | " .. v428 .. "ms"
        end

        function f38(p141, p142)
          local gsub4 = tostring(p141 or "")
          local v448 = tostring(displayName or "")
          local v449 = tostring(name4 or "")

          if p142 and p142 ~= "" then
            gsub4 = gsub4:gsub("^%s*" .. p142:gsub("([^%w])", "%%%1") .. "%s*", "")
          end

          if v448 ~= "" then
            gsub4 = gsub4:gsub("^%s*" .. v448:gsub("([^%w])", "%%%1") .. "%s*", "")
          end

          if v449 ~= "" then
            gsub4 = gsub4:gsub("^%s*@?" .. v449:gsub("([^%w])", "%%%1") .. "%s*", "")
          end

          return (gsub4:gsub("^%s+", ""))
        end

        v429 = {
          SANDSTORM = "SAND STORM", MANAGER = "GLITCHED", ["THE LOST FOREST"] = "LOST FOREST",
          ["RADIANT FOREST"] = "THE RADIANT FOREST",
        }

        v430 = {
          GLITCHED = { "resolved" },
          CYBERSPACE = { "signal lost", "lost" },
          DREAMSPACE = { "waking", "wake" },
        }

        v431 = nil
        v432 = 0

        function f39()
          local mainInterface4 = playerGui:FindFirstChild("MainInterface")

          if not mainInterface4 then
            return nil
          end

          if v431 and v431.Parent == mainInterface4 then
            local count5 = 0

            for index77, value71 in ipairs(v431:GetChildren()) do
              if value71:IsA("TextLabel") then
                count5 = count5 + 1
              end
            end

            if count5 ~= v432 then
              v431 = nil
              v432 = 0
            end
          end

          if v431 and v431.Parent == mainInterface4 then
            local v450 = v431
            local text10 = v450.Text or ""

            if text10:find("ERRORWHILERETRIEVING") or text10:find("ERROR") then
              if not v19 then
                v19 = true
                return "GLITCHED"
              end

              return nil
            end

            for index78, value72 in ipairs(v450:GetChildren()) do
              if value72:IsA("TextLabel") then
                local sS3 = value72.Text:match("%[%s*(.-)%s*%]")

                if sS3 and sS3 ~= "" then
                  v19 = false
                  local gsub5 = sS3:upper():gsub("%s+", " ")
                  return v429[gsub5] or gsub5
                end
              end
            end

            v431 = nil
          end

          for index79, value73 in ipairs(mainInterface4:GetChildren()) do
            if value73:IsA("TextLabel") then
              local count6 = 0

              for index80, value74 in ipairs(value73:GetChildren()) do
                if value74:IsA("TextLabel") then
                  count6 = count6 + 1
                end
              end

              if count6 ~= 0 then
                local text11 = value73.Text or ""

                if text11:find("ERRORWHILERETRIEVING") or text11:find("ERROR") then
                  v431 = value73
                  v432 = count6

                  if not v19 then
                    v19 = true
                    return "GLITCHED"
                  end

                  return nil
                end

                for index81, value75 in ipairs(value73:GetChildren()) do
                  if value75:IsA("TextLabel") then
                    local sS4 = value75.Text:match("%[%s*(.-)%s*%]")

                    if sS4 and sS4 ~= "" then
                      v431 = value73
                      v432 = count6
                      v19 = false
                      local gsub6 = sS4:upper():gsub("%s+", " ")
                      return v429[gsub6] or gsub6
                    end
                  end
                end
              end
            end
          end

          v19 = false
          return nil
        end

        v433 = {
          ExtractionPatterns = {
            "HAS FOUND (.-),%s*CHANCE OF 1 IN (.+)", "HAS FOUND (.-) CHANCE OF 1 IN (.+)",
          },
          CustomTriggers = {
            ["All hail, The (.+)"] = {
              "Monarch", "1 in 3,000,000,000",
              "https://static.wikia.nocookie.net/sol-rng/images/c/c7/Monarch_Collection_New.png/revision/latest?cb=20250209115416",
              "# > All hail, The {nick} {rarity}",
            },
            ["(.+) Has Become PIXELATED!"] = {
              "Pixelation", "1 in 1,073,741,824",
              "https://static.wikia.nocookie.net/sol-rng/images/9/9e/PixelationCollection.gif/revision/latest?cb=20251120120600",
              "# > {nick} Has Become PIXELATED!",
            },
            ["The Blinding Light has devoured (.+)"] = {
              "Luminosity", "1 in 1,200,000,000",
              "https://static.wikia.nocookie.net/sol-rng/images/6/6b/Nonpixelatedlumicollection.gif/revision/latest?cb=20250603000012",
              "# > The Blinding Light has devoured {nick} {rarity}",
            },
            ["(.+) experienced the literal nightmare."] = {
              "N̰̪̏Y̑C̪̑T̴̩̦̦̉̕Òᠡ̰᳘̽̐̔H̲̻ẘO͵̡̘̐̽B̸̵̠̌̈Ḯ᷄̍ᭅᵌÃᶃᶂ̓ᶀᵑ",
              "1 in 1,011,111,010",
              "https://static.wikia.nocookie.net/sol-rng/images/b/b7/Nyctophobia-Collection.gif/revision/latest?cb=20251125084752",
              "# > {nick} experienced the literal nightmare. {rarity}",
            },
            ["(.+) Has Found The %[%?%?%?%?%?%?%?%] between %[Positive%] and %[Negative%]."] = {
              "『Equinox』", "1 in 2,500,000,000",
              "https://static.wikia.nocookie.net/sol-rng/images/a/a7/EquinoxNewCollection.gif/revision/latest?cb=20250802092429",
              "# > {nick} Has Found The [???????] between [Positive] and [Negative]. {rarity}",
            },
            ["(.+) has found %?%?%?, chance of 1 in 1,999,999,999 %[BREAKTHROUGH!%]"] = {
              "BREAKTHROUGH", "1 in 1,999,999,999",
              "https://static.wikia.nocookie.net/sol-rng/images/7/70/BreakthroughCollection.gif/revision/latest?cb=20260117092324",
              "# > {nick} has found ???, chance of 1 in 1,999,999,999 [BREAKTHROUGH!]",
            },
            ["(.+) HAS CRAFTED Matrix : Steampunk %[ GLORIOUS Crafted %]"] = {
              "MATRIX : STEAMPUNK", "1 in 536,870,912",
              "https://static.wikia.nocookie.net/sol-rng/images/a/af/Matrix_steampunk_collection.gif/revision/latest?cb=20250506215543",
              "# > {nick} Has crafted MATRIX : STEAMPUNK ({rarity})",
            },
            ["(.+) has stood before the God%."] = {
              "Oppression", "1 in 666,666,666",
              "https://static.wikia.nocookie.net/sol-rng/images/6/63/OppressionCollectionNew.gif/revision/latest?cb=20250920081607",
              "# > {nick} has stood before the God.",
            },
            ["(.+) didn't wake up%."] = {
              "Dreammetric", "1 in 750,000,000",
              "https://static.wikia.nocookie.net/sol-rng/images/9/97/Dreammetric_Collection.gif/revision/latest?cb=20250901165833",
              "# > {nick} didn't wake up.",
            },
            ["(.+) has become ███'█ PERFECT PUPPET%."] = {
              "Illusionary", "1 in 800,000,000",
              "https://static.wikia.nocookie.net/sol-rng/images/7/7f/Illusionary_collection.gif/revision/latest?cb=20251116022942",
              "# > {nick} has become ###'# PERFECT PUPPET.",
            },
            ["error occurred from (.+)%."] = {
              "Glitch", "1 in 500,000,000",
              "https://static.wikia.nocookie.net/sol-rng/images/a/a1/Era8glitchcollection.gif/revision/latest?cb=20240630225204",
              "# > error occurred from {nick}.",
            },
            ["(.+) was lost in their dreams%."] = {
              "Borealis", "1 in 700,000,000",
              "https://static.wikia.nocookie.net/sol-rng/images/4/44/BorealisCollection.gif/revision/latest?cb=20260119161429",
              "# > {nick} was lost in their dreams.",
            },
            ["(.+) has tamed the Ruler of Beneath%."] = {
              "Leviathan", "1 in 900,000,000",
              "https://static.wikia.nocookie.net/sol-rng/images/a/a4/LeviathanCollection.gif/revision/latest?cb=20260117095725",
              "# > {nick} has tamed the Ruler of Beneath.",
            },
          },
          Thumbnails = {},
          DefaultColor = 5793266,
          SpecificColors = {
            Monarch = 7733396,
            Pixelation = 65416,
            luminosity = 15465210,
            BREAKTHROUGH = 12370626,
            Oppression = 1118481,
            Dreammetric = 16745922,
            Illusionary = 4491519,
            Glitch = 16777215,
            Borealis = 16745922,
            Leviathan = 9498256,
          },
          MinimumDetectionThreshold = 99000,
        }

-- https://discord.gg/AwGHNh7Z7T
        v434 = extractWebhooks(webhook)
        v435 = parseDiscordIds(discordId2)
        v436 = parseDiscordIds(userConfig.RoleId)
        v437 = 999000000

        if type(pingThreshold2) == "number" then
          v437 = pingThreshold2
        end

        function f14()
          return userConfig.PingEden == true
        end

        function f15(key13)
          for index82, value76 in ipairs(v41) do
            if key13 == value76 then
              return false
            end
          end

          return userConfig.PingBiomes[key13] == true
        end

        function f16(key14)
          return userConfig.PingMerchants[key14] == true
        end

        function f40(key15)
          if key15 and userConfig.CustomPingIds and type(userConfig.CustomPingIds[key15]) == "string"
            and userConfig.CustomPingIds[key15] ~= "" then
            local v451, v452 = parseCustomPingIds(userConfig.CustomPingIds[key15])
            local v453 = {}

            for index83, value77 in ipairs(v451) do
              v453[#v453 + 1] = "<@" .. value77 .. ">"
            end

            for index84, value78 in ipairs(v452) do
              v453[#v453 + 1] = "<@&" .. value78 .. ">"
            end

            if #v453 > 0 then
              return table.concat(v453, " ") .. " "
            end

            return ""
          else
            local v454 = {}

            for index85, value79 in ipairs(v435) do
              v454[#v454 + 1] = "<@" .. value79 .. ">"
            end

            for index86, value80 in ipairs(v436) do
              v454[#v454 + 1] = "<@&" .. value80 .. ">"
            end

            if #v454 == 0 then
              return ""
            end

            return table.concat(v454, " ") .. " "
          end
        end

        local v455 = syn and syn.request or request or http_request
          or function(p143) return httpService:PostAsync(p143.Url, p143.Body) end

        if #v434 == 0 then
          errorNotify("- Error: No Webhook configured! -")
          macroRunning = false
          _G.__BIOME_MACRO_RUNNING = false

          if addStatusBadge2 then
            addStatusBadge2:SetState("offline")
          end

          if addStatusBadge22 then
            addStatusBadge22:SetState("offline")
          end

          pcall(function() ui:SetSidebarUserStatus(false) end)

          if v55 then
            v55:SetEnabled(true)
          end

          if v56 then
            v56:SetEnabled(false)
          end

          return
        else
          function f41(method, p144, p145)
            local headers = {
              Authorization = "Bot MTUxMjU4OTE0NDUyMDUyNzkwNQ.G31wRm.LtYcFWxX-3G76zi75ypbx1JLuotKKBXm3meH94",
              ["Content-Type"] = "application/json",
            }

            local jsonEncode4 = p145 and httpService:JSONEncode(p145) or nil

            return v455({
              Url = "https://discord.com/api/v10" .. p144,
              Method = method,
              Headers = headers,
              Body = jsonEncode4,
            })
          end

          function f17(p146)
            if not p146 then
              return 0
            else
              local match4 = p146:match("1 in (.*)")

              if not match4 then
                match4 = p146
              end

              return tonumber((match4:gsub("%D", ""))) or 0
            end
          end

          function f30()
            if _G.__BIOME_REMOVED then
              return
            end

            task.spawn(function()
              local v456 = {}

              for index87, value81 in ipairs({
                { id = "1493361999978172566", key = "glitched", label = "Glitched" },
                { id = "1493362047419940905", key = "dreamspace", label = "Dreamspace" },
                { id = "1493362083495153875", key = "cyberspace", label = "Cyberspace" },
              }) do
                local v457 = value81

                if v457.id ~= "" then
                  local v458, v459 = pcall(function()
                    return f41("GET", "/channels/" .. v457.id)
                  end)

                  if v458 and v459 and v459.StatusCode == 200 then
                    local v460, v461 = pcall(function()
                      return httpService:JSONDecode(v459.Body)
                    end)

                    if v460 and v461 and v461.name then
                      local match5 = v461.name:match(v457.label .. "%s*:%s*(%d+)")
                        or v461.name:match(v457.key .. "[%s%-:]+spawned[%s%-:]*(%d+)")
                        or v461.name:match(v457.key .. "[%s%-:]+(%d+)")
                        or v461.name:match("(%d+)")

                      if match5 then
                        v456[v457.key] = tonumber(match5)
                      end
                    end
                  end
                end
              end

              if next(v456) then
                enqueueDashboardEvent("/webhook/discord-sync-counters", { counters = v456 })
              end
            end)
          end

          function f18(key16, p147)
            local v462 = v40[key16] or { 5793266, nil, false }
            local v463 = os.time()
            local v464

            if p147 then
              v464 = "> # Biome Ended - " .. key16
            else
              v464 = "> # Biome Started - " .. key16

              if psLink ~= "" then
                v464 = v464 .. "\n> **Private Server Link:** " .. psLink
              end
            end

            local v465 = {
              title = f36(v463),
              description = v464,
              color = v462[1],
              footer = {
                text = f37(),
                icon_url = "https://media.discordapp.net/attachments/1296977365150335049/1473317870292439103/8UXDknU.png?ex=6995c5b1&is=69947431&hm=d1daa8d58782b32484f96e01450048d8111325dba1143b6c8bd0f09964972860&animated=true",
              },
            }

            if v462[2] then
              v465.thumbnail = { url = v462[2] }
            end

            return v465
          end

          function f19(p148)
            return p148:gsub("%s*,.*$", ""):gsub("%s*%[.-%]", ""):gsub("^%s*(.-)%s*$", "%1")
          end

          function f31(p149)
            if _G.__BIOME_REMOVED then
              return
            end

            local v466 = nil
            local v467 = nil
            local v468 = nil

            if p149 == "GLITCHED" then
              v466 = "1493361999978172566"
              v467 = "glitched"
              v468 = "Glitched"

              task.spawn(function()
                local v469, v470 = pcall(function() return f41("GET", "/channels/" .. v466) end)
                local v471 = not v469 or not v470 or v470.StatusCode ~= 200
                local name5

                if v471 then
                  warn("[RareBiomeCounter] Failed to fetch channel " .. v466 .. " for " .. p149)
                  return
                else
                  local v472, v473 = pcall(function()
                    return httpService:JSONDecode(v470.Body)
                  end)

                  if not v472 or not v473 or not v473.name then
                    return
                  else
                    local name6 = v473.name

                    local match6 = name6:match(v468 .. "%s*:%s*(%d+)")
                      or name6:match(v467 .. "[%s%-:]+spawned[%s%-:]*(%d+)")
                      or name6:match(v467 .. "[%s%-:]+(%d+)") or name6:match("(%d+)")

                    name5 = v468 .. ": " .. (match6 and tonumber(match6) + 1 or 1)

                    local v474, v475 = pcall(function()
                      return f41("PATCH", "/channels/" .. v466, { name = name5 })
                    end)

                    if not v474 or not v475 or v475.StatusCode ~= 200 and v475.StatusCode ~= 204 then
                      warn("[RareBiomeCounter] Failed to update channel for " .. p149)
                    end

                    f30()
                    return
                  end
                end
              end)

              return
            elseif p149 == "DREAMSPACE" then
              v466 = "1493362047419940905"
              v467 = "dreamspace"
              v468 = "Dreamspace"

              task.spawn(function()
                local v476, v477 = pcall(function() return f41("GET", "/channels/" .. v466) end)
                local v478 = not v476 or not v477 or v477.StatusCode ~= 200
                local name7

                if v478 then
                  warn("[RareBiomeCounter] Failed to fetch channel " .. v466 .. " for " .. p149)
                  return
                else
                  local v479, v480 = pcall(function()
                    return httpService:JSONDecode(v477.Body)
                  end)

                  if not v479 or not v480 or not v480.name then
                    return
                  else
                    local name8 = v480.name

                    local match7 = name8:match(v468 .. "%s*:%s*(%d+)")
                      or name8:match(v467 .. "[%s%-:]+spawned[%s%-:]*(%d+)")
                      or name8:match(v467 .. "[%s%-:]+(%d+)") or name8:match("(%d+)")

                    name7 = v468 .. ": " .. (match7 and tonumber(match7) + 1 or 1)

                    local v481, v482 = pcall(function()
                      return f41("PATCH", "/channels/" .. v466, { name = name7 })
                    end)

                    if not v481 or not v482 or v482.StatusCode ~= 200 and v482.StatusCode ~= 204 then
                      warn("[RareBiomeCounter] Failed to update channel for " .. p149)
                    end

                    f30()
                    return
                  end
                end
              end)

              return
            elseif p149 == "CYBERSPACE" then
              v466 = "1493362083495153875"
              v467 = "cyberspace"
              v468 = "Cyberspace"

              task.spawn(function()
                local v483, v484 = pcall(function() return f41("GET", "/channels/" .. v466) end)
                local v485 = not v483 or not v484 or v484.StatusCode ~= 200
                local name9

                if v485 then
                  warn("[RareBiomeCounter] Failed to fetch channel " .. v466 .. " for " .. p149)
                  return
                else
                  local v486, v487 = pcall(function()
                    return httpService:JSONDecode(v484.Body)
                  end)

                  if not v486 or not v487 or not v487.name then
                    return
                  else
                    local name10 = v487.name

                    local match8 = name10:match(v468 .. "%s*:%s*(%d+)")
                      or name10:match(v467 .. "[%s%-:]+spawned[%s%-:]*(%d+)")
                      or name10:match(v467 .. "[%s%-:]+(%d+)") or name10:match("(%d+)")

                    name9 = v468 .. ": " .. (match8 and tonumber(match8) + 1 or 1)

                    local v488, v489 = pcall(function()
                      return f41("PATCH", "/channels/" .. v466, { name = name9 })
                    end)

                    if not v488 or not v489 or v489.StatusCode ~= 200 and v489.StatusCode ~= 204 then
                      warn("[RareBiomeCounter] Failed to update channel for " .. p149)
                    end

                    f30()
                    return
                  end
                end
              end)

              return
            else
              return
            end
          end

          function f20(p150, p151, p152, p153, p154)
            local v490 = {
              title = f36((os.time())),
              description = p153
                or string.format("# > Aura rolled: **%s** chance 1 in %s", p150, p151),
              color = p154 or v433.DefaultColor,
              footer = {
                text = f37(),
                icon_url = "https://media.discordapp.net/attachments/1296977365150335049/1473317870292439103/8UXDknU.png?ex=6995c5b1&is=69947431&hm=d1daa8d58782b32484f96e01450048d8111325dba1143b6c8bd0f09964972860&animated=true",
              },
            }

            if p152 then
              v490.thumbnail = { url = p152 }
            end

            return v490
          end

          function f21(key17)
            globalStats.TotalBiomes = globalStats.TotalBiomes + 1

            if not globalStats.BiomeDetails[key17] then
              globalStats.BiomeDetails[key17] = 0
            end

            globalStats.BiomeDetails[key17] = globalStats.BiomeDetails[key17] + 1
            globalStats.BiomeLastSeen[key17] = os.time()

            v12.BiomeCount = v12.BiomeCount + 1
            name = key17
            v13 = os.time()
            SaveDataDebounced()

            if addLogConsole then
              addLogConsole:Log("Biome detected: " .. key17, "SUCCESS")
            end

            if key17 == "GLITCHED" or key17 == "DREAMSPACE" or key17 == "CYBERSPACE" then
              f31(key17)
            end
          end

          function f22(key18, p155)
            if v433.SpecificColors[key18] then
              return v433.SpecificColors[key18]
            elseif p155 >= 1000000000 then
              return 16766720
            elseif p155 >= 500000000 then
              return 16729344
            elseif p155 >= 100000000 then
              return 10040012
            elseif p155 >= 10000000 then
              return 2003199
            else
              if p155 >= 1000000 then
                return 52945
              end

              return v433.DefaultColor
            end
          end

          function f23()
            local v491 = os.time()
            local v492 = "> # Mari has arrived on the island."

            if psLink ~= "" then
              v492 = v492 .. "\n> **Private Server Link:** " .. psLink
            end

            return {
              title = f36(v491),
              description = v492,
              color = 8149550,
              thumbnail = {
                url = "https://github.com/gustaslaoq/MobileMacro/blob/main/images/Mari.png?raw=true",
              },
              footer = {
                text = f37(),
                icon_url = "https://media.discordapp.net/attachments/1296977365150335049/1473317870292439103/8UXDknU.png?ex=6995c5b1&is=69947431&hm=d1daa8d58782b32484f96e01450048d8111325dba1143b6c8bd0f09964972860&animated=true",
              },
            }
          end

          function f24()
            return {
              title = f36((os.time())),
              description = "> # Eden has appeared in the limbo",
              color = 0,
              thumbnail = {
                url = "https://github.com/gustaslaoq/MobileMacro/blob/main/images/Eden.png?raw=true",
              },
              footer = {
                text = f37(),
                icon_url = "https://media.discordapp.net/attachments/1296977365150335049/1473317870292439103/8UXDknU.png?ex=6995c5b1&is=69947431&hm=d1daa8d58782b32484f96e01450048d8111325dba1143b6c8bd0f09964972860&animated=true",
              },
            }
          end

          function f25()
            local v493 = os.time()
            local v494 = "> # Jester has arrived on the island!!"

            if psLink ~= "" then
              v494 = v494 .. "\n> **Private Server Link:** " .. psLink
            end

            return {
              title = f36(v493),
              description = v494,
              color = 5312199,
              thumbnail = {
                url = "https://github.com/gustaslaoq/MobileMacro/blob/main/images/Jester.png?raw=true",
              },
              footer = {
                text = f37(),
                icon_url = "https://media.discordapp.net/attachments/1296977365150335049/1473317870292439103/8UXDknU.png?ex=6995c5b1&is=69947431&hm=d1daa8d58782b32484f96e01450048d8111325dba1143b6c8bd0f09964972860&animated=true",
              },
            }
          end

          function f26(p156)
            local v495 = os.time()

            local v496 = v12.StartTick > 0 and f35(math.max(0, os.time() - v12.StartTick))
              or "0s"

            return {
              title = f36(v495),
              description = string.format([[
> ## -- Macro Stopped --
> **Session Time:** %s
> **Session Biome Count:** %d
> **Merchant Count:** %d
%s> -# Message <@946569782508019764> (gustaslaoq) for bugs]], v496, v12.BiomeCount, v12.MerchantCount, ""),
              color = 16711680,
              footer = {
                text = f37(),
                icon_url = "https://media.discordapp.net/attachments/1296977365150335049/1473317870292439103/8UXDknU.png?ex=6995c5b1&is=69947431&hm=d1daa8d58782b32484f96e01450048d8111325dba1143b6c8bd0f09964972860&animated=true",
              },
            }
          end

          function f42(key19, p157)
            local v497 = v40[key19] or { 5793266, nil, false }
            local v498 = os.time()
            local v499 = {}

            for index88, value82 in ipairs(p157) do
              v499[#v499 + 1] = tostring(value82.Amount) .. "x " .. value82.Name
            end

            return {
              title = f36(v498),
              description = "> # Using " .. table.concat(v499, ", ") .. " in " .. key19,
              color = v497[1],
              footer = {
                text = f37(),
                icon_url = "https://media.discordapp.net/attachments/1296977365150335049/1473317870292439103/8UXDknU.png?ex=6995c5b1&is=69947431&hm=d1daa8d58782b32484f96e01450048d8111325dba1143b6c8bd0f09964972860&animated=true",
              },
            }
          end

          function f27()
            local v500 = os.time()
            local v501 = "> # Rin has arrived on the island!!!"

            if psLink ~= "" then
              v501 = v501 .. "\n> **Private Server Link:** " .. psLink
            end

            return {
              title = f36(v500),
              description = v501,
              color = 16099850,
              thumbnail = {
                url = "https://github.com/gustaslaoq/MobileMacro/blob/main/images/Rin.png?raw=true",
              },
              footer = {
                text = f37(),
                icon_url = "https://media.discordapp.net/attachments/1296977365150335049/1473317870292439103/8UXDknU.png?ex=6995c5b1&is=69947431&hm=d1daa8d58782b32484f96e01450048d8111325dba1143b6c8bd0f09964972860&animated=true",
              },
            }
          end

          local function f46()
            local v502 = os.time()

            local v503 = string.format([[
> ## -- Macro Started --
%s> **Private Server:** %s
> **WARNING:** Your game must be in English for the script to work
> -# Message <@946569782508019764> (gustaslaoq) for bugs]], "", psLink ~= "" and psLink or "None")

            if antiAfk2 then
              v503 = v503 .. "\n> *AntiAfk is activated, you won't be kicked.*"
            end

            return {
              title = f36(v502),
              description = v503,
              color = 65535,
              footer = {
                text = f37(),
                icon_url = "https://media.discordapp.net/attachments/1296977365150335049/1473317870292439103/8UXDknU.png?ex=6995c5b1&is=69947431&hm=d1daa8d58782b32484f96e01450048d8111325dba1143b6c8bd0f09964972860&animated=true",
              },
            }
          end

          task.spawn(function()
            local v504, v505 = pcall(function()
              return coreGui:WaitForChild("RobloxPromptGui", 60)
            end)

            if not v504 or not v505 then
              return
            else
              local v506, v507 = pcall(function()
                return v505:WaitForChild("promptOverlay", 60)
              end)

              if not v506 or not v507 then
                return
              else
                local connect3 = v507.ChildAdded:Connect(function(child)
                  if child.Name == "ErrorPrompt" and macroRunning then
                    if userConfig.PSLink ~= ""
                      and (userConfig.PSLink:lower():find("roblox.com/share")
                        or userConfig.PSLink:lower():find("share?code=")) then
                      notify(
                        "- Warning: Error prompt detected while using a Share Link -- ignoring, macro keeps running -",
                        Color3.fromRGB(255, 200, 80)
                      )
                    else
                      task.spawn(function() pcall(v36) end)
                    end
                  end
                end)

                table.insert(v20, connect3)
                return
              end
            end
          end)

          v438 = {}
          v439 = {}
          v440 = false

          function f28(p158, p159, p160)
            local v508 = tostring(math.floor(os.time() / 10)) .. "_" .. tostring(p158) .. "_"
              .. (p159 and tostring(p159.description) or "nil")

            if not _G.__BIOME_SENT_HASHES then
              _G.__BIOME_SENT_HASHES = {}
            end

            local v509 = _G.__BIOME_SENT_HASHES[v508]

            if v509 and os.time() - v509 < 10 then
              warn("[Send] Duplicate embed blocked: " .. v508:sub(1, 60))
              return
            end

            _G.__BIOME_SENT_HASHES[v508] = os.time()

            table.insert(v438, {
              execute = function()
                local jsonEncode5 = httpService:JSONEncode({
                  content = p158 ~= "" and p158 or nil,
                  embeds = p159 and { p159 } or nil,
                })

                for index89, value83 in ipairs(v434) do
                  local v510 = value83

                  if v439[v510] and os.time() < v439[v510] then
                    warn("[Webhook] Skipping " .. tostring(v510:sub(1, 40)) .. " (rate limited)")
                  else
                    if v439[v510] then
                      v439[v510] = nil
                    end

                    local v511 = os.clock()
                    local v512 = false
                    local v513 = "Unknown"

                    for i16 = 1, 3 do
                      local v514, v515 = pcall(function()
                        return v455({
                          Url = v510,
                          Method = "POST",
                          Headers = { ["Content-Type"] = "application/json" },
                          Body = jsonEncode5,
                        })
                      end)

                      if v514 and v515 then
                        local statusCode4 = v515.StatusCode or 0

                        if statusCode4 == 204 or statusCode4 == 200 then
                          v512 = true
                          v428 = math.floor((os.clock() - v511) * 1000)
                          break
                        elseif statusCode4 == 429 then
                          v513 = "Rate Limited (429)"
                          v439[v510] = os.time() + 60

                          warn("[Webhook] Rate limited on " .. tostring(v510:sub(1, 40))
                            .. ", cooling down for 60s")

                          break
                        elseif statusCode4 >= 500 then
                          v513 = "Server Error (" .. statusCode4 .. ")"
                          task.wait(i16 * 0.5)
                        else
                          v513 = "Client Error (" .. statusCode4 .. ")"
                          break
                        end
                      else
                        v513 = "Request failed"
                        task.wait(i16 * 1)
                      end
                    end

                    if not v512 then
                      warn("[Webhook] Failed after 3 attempts. Last error: " .. v513)
                    end
                  end
                end

                local v516 = p160 and not _G.__BIOME_REMOVED and p159
                local v517, v518, v519, v520

                if v516 then
                  if not (type(p159.description) == "string"
                    and p159.description:find("Biome Ended") ~= nil) then
                    v517 = {}

                    for key20, value84 in pairs(p159) do
                      v517[key20] = value84
                    end

                    v518 = "?"
                    v519 = "?"
                    v520 = "?"

                    pcall(function()
                      v518 = isInLimbo() and "true" or "false"
                      v519 = v18 and "chat" or "gui"
                      v520 = tostring(displayName) .. "(@" .. tostring(name4) .. ")"
                    end)

                    v517.description = tostring(v517.description or "")
                      .. "\n> **is in limbo:** " .. v518 .. "\n> **detection mode:** " .. v519
                      .. "\n> **player:** " .. v520

                    pcall(function()
                      f41("POST", "/channels/1488345964363382887/messages", {
                        content = p158 ~= "" and p158 or nil,
                        embeds = { v517 },
                      })
                    end)
                  end
                end
              end,
            })

            task.spawn(f43)
          end

          function f43()
            if v440 then
              return
            else
              local v521 = os.time()

              for key21, value85 in pairs(v439) do
                if v521 >= value85 then
                  v439[key21] = nil
                end
              end

              v440 = true

              while #v438 > 0 do
                local v522, v523 = pcall(table.remove(v438, 1).execute)

                if not v522 then
                  warn("[Webhook Queue Error] " .. tostring(v523))
                end

                task.wait(0.1)
              end

              v440 = false
              return
            end
          end

          local v524 = task.spawn(function()
            while macroRunning do
              task.wait(30)
              local v525 = os.time()

              if _G.__BIOME_SENT_HASHES then
                for key22, value86 in pairs(_G.__BIOME_SENT_HASHES) do
                  if type(value86) == "number" and v525 - value86 >= 10 then
                    _G.__BIOME_SENT_HASHES[key22] = nil
                  end
                end
              end
            end
          end)

          table.insert(v21, v524)
          v441 = {}
          v442 = {}

          function f29(key23, p161)
            if not key23 or not p161 then
              return
            else
              local v526 = os.time()
              local v527 = v441[key23]

              if v527 and v526 - v527 < 300 then
                return
              else
                v441[key23] = v526
                v12.MerchantCount = v12.MerchantCount + 1

                if v16 then
                  enqueueMerchantFound({
                    sessionId = v16,
                    userId = tostring(localPlayer.UserId),
                    username = localPlayer.Name,
                    merchantName = key23,
                    timestamp = os.time(),
                  })
                end

                local v528 = f16(key23) and f40(key23) or ""

                if key23 == "Mari" then
                  f28(v528, f23(), false)
                elseif key23 == "Jester" then
                  f28(v528, f25(), false)
                elseif key23 == "Rin" then
                  f28(v528, f27(), false)
                end

                notify("- Merchant Detected: " .. tostring(key23) .. " -")

                if addLogConsole then
                  addLogConsole:Log("Merchant: " .. tostring(key23), "INFO")
                end

                return
              end
            end
          end

          v443 = { Mari = true, Jester = true, Rin = true }

          local v529 = task.spawn(function()
            while macroRunning do
              if v3.forcedMerchant then
                local forcedMerchant = v3.forcedMerchant
                v3.forcedMerchant = nil
                v441[forcedMerchant] = nil
                f29(forcedMerchant, {})
              end

              local v530 = {}

              for index90, value87 in ipairs(scanMerchantModels()) do
                v530[value87.Name] = true
                f29(value87.Name, value87.Model)
              end

              for key24 in pairs(v441) do
                if v443[key24] then
                  if not v530[key24] then
                    v442[key24] = (v442[key24] or 0) + 1

                    if v442[key24] >= 3 then
                      v441[key24] = nil
                      v442[key24] = nil
                    end
                  else
                    v442[key24] = nil
                  end
                end
              end

              task.wait(1)
            end
          end)

          table.insert(v21, v529)

          function v33()
            if v15 then
              return
            end

            v15 = true
            f28("", f26("Manual"), false)

            if v16 then
              enqueueDashboardEvent("/webhook/session-end", {
                sessionId = v16,
                userId = tostring(localPlayer.UserId),
                totalBiomes = v12.BiomeCount,
                totalMerchants = v12.MerchantCount,
                timestamp = os.time(),
              })

              v16 = nil
            end
          end

          jsonEncode3 = httpService:JSONEncode({ embeds = { (f46()) } })

          for index91, value88 in ipairs(v434) do
            local url2 = value88

            for i17 = 1, 3 do
              local v531, v532 = pcall(function()
                return v455({
                  Url = url2,
                  Method = "POST",
                  Headers = { ["Content-Type"] = "application/json" },
                  Body = jsonEncode3,
                })
              end)

              if v531 and v532 then
                local statusCode5 = v532.StatusCode or 0

                if statusCode5 == 204 or statusCode5 == 200 then
                  break
                end

                if statusCode5 == 429 then
                  warn("[Webhook] Rate limited during session-end send, skipping retry")
                  break
                end

                task.wait(0.5)
              else
                task.wait(1)
              end
            end
          end

          if addLogConsole then
            addLogConsole:Log("Macro started", "SUCCESS")
          end

          if antiAfk2 then
            local v533 = task.spawn(function()
              while macroRunning do
                local antiAfkInterval = type(userConfig.AntiAfkInterval) == "number"
                    and userConfig.AntiAfkInterval
                  or 300

                task.wait(math.max(30, antiAfkInterval))

                if macroRunning then
                  pcall(function()
                    virtualUser:CaptureController()
                    virtualUser:ClickButton2(Vector2.new())
                  end)
                end
              end
            end)

            table.insert(v21, v533)
          end

          function f32(p162)
            if not p162 then
              return nil
            else
              local v534 = string.lower(p162)

              if string.find(v534, "coral") then
                return "CORAL REEF"
              elseif string.find(v534, "volcan") then
                return "VOLCANO"
              elseif string.find(v534, "ice") then
                return "ICE"
              elseif string.find(v534, "rainy") then
                return "RAINY"
              elseif string.find(v534, "snowy") then
                return "SNOWY"
              elseif string.find(v534, "sand") or string.find(v534, "storm") then
                return "SAND STORM"
              elseif string.find(v534, "windy") then
                return "WINDY"
              elseif string.find(v534, "starfall") then
                return "STARFALL"
              elseif string.find(v534, "hell") then
                return "HELL"
              elseif string.find(v534, "dreamspace") then
                return "DREAMSPACE"
              elseif string.find(v534, "glitched") then
                return "GLITCHED"
              elseif string.find(v534, "heaven") then
                return "HEAVEN"
              elseif string.find(v534, "null") then
                return "NULL"
              elseif string.find(v534, "cyberspace") then
                return "CYBERSPACE"
              elseif string.find(v534, "aurora") then
                return "AURORA"
              elseif string.find(v534, "corruption") then
                return "CORRUPTION"
              else
                if string.find(v534, "singularity") then
                  return "SINGULARITY"
                end

                return nil
              end
            end
          end

          startWaterConfigLoop()

          function f44(key25)
            return userConfig.MutedBiomes and userConfig.MutedBiomes[key25] == true
          end

          function f33(key26, p163)
            local v535 = key26 == "GLITCHED" or key26 == "CYBERSPACE" or key26 == "DREAMSPACE"
              or key26 == "SINGULARITY" or key26 == "THE RADIANT FOREST"

            if p163 then
              f28("", f18(key26, true), v535)
            elseif v40[key26][3] then
              f28("@everyone ", f18(key26, false), v535)
            elseif f15(key26) then
              f28(f40(key26), f18(key26, false), v535)
            else
              f28("", f18(key26, false), v535)
            end
          end

          function f34()
            local character4 = localPlayer.Character
            local humanoid = character4 and character4:FindFirstChildOfClass("Humanoid")

            if humanoid and humanoid.Health > 0 then
              humanoid.Health = 0
            end
          end

          v444 = {
            ["Lucky Potion"] = 1,
            ["Speed Potion"] = 1,
            ["Fortune Potion I"] = 2,
            ["Fortune Potion II"] = 2,
            ["Fortune Potion III"] = 2,
            ["Haste Potion I"] = 2,
            ["Haste Potion II"] = 2,
            ["Haste Potion III"] = 2,
            ["Strange Potion I"] = 3,
            ["Strange Potion II"] = 3,
            ["Rune of Everything"] = 4,
            ["Warp Potion"] = 5,
            ["Transcendent Potion"] = 5,
            ["Potion of Bound"] = 6,
            ["Heavenly Potion"] = 7,
            ["Godlike Potion"] = 8,
          }

          v445 = false

          function f45(key27)
            if userConfig.AutoResetOnRareBiome then
              if key27 == "GLITCHED" or key27 == "CYBERSPACE" or key27 == "DREAMSPACE" then
                notify(
                  "- Auto Reset: " .. key27 .. " detected -- resetting -",
                  Color3.fromRGB(255, 120, 60)
                )

                task.spawn(f34)
              end
            end

            local v536

            if userConfig.AutoPop and userConfig.AutoPop.Enabled then
              v536 = userConfig.AutoPop.Rules[key27]

              if v536 and #v536 > 0 then
                task.spawn(function()
                  if v445 then
                    return
                  else
                    v445 = true
                    local af2 = _G.__AF

                    if af2 then
                      local total3 = 0

                      while isAutoPopPaused(af2) and total3 < 60 do
                        task.wait(0.5)
                        total3 = total3 + 0.5
                      end

                      acquireAutoPopPause(af2)
                    end

                    local v537 = {}

                    for index92, value89 in ipairs(v536) do
                      v537[#v537 + 1] = {
                        Name = value89.Name,
                        Amount = value89.Amount,
                        Priority = v444[value89.Name] or 99,
                      }
                    end

                    table.sort(v537, function(p164, p165)
                      return p164.Priority < p165.Priority
                    end)

                    f28("", f42(key27, v537), false)

                    for index93, value90 in ipairs(v537) do
                      local v538 = index93 == #v537

                      inputHelper.useInventoryItemExact(value90.Name, value90.Amount, {
                        NotifyFailure = false,
                        Attempts = 2,
                        CloseAfter = v538,
                      })

                      if not v538 then
                        task.wait(0.4)
                      end
                    end

                    inputHelper.clearInventorySearch()

                    if af2 then
                      releaseAutoPopPause(af2)
                    end

                    v445 = false
                    return
                  end
                end)
              end
            end
          end

          local v539 = task.spawn(function()
            while macroRunning do
              local forcedBiome = f39()

              if v3.forcedBiome then
                forcedBiome = v3.forcedBiome
                v3.forcedBiome = nil
              end

              local biomeScanInterval = type(userConfig.BiomeScanInterval) == "number"
                  and userConfig.BiomeScanInterval
                or 0.5

              if forcedBiome == "THE LIMBO" then
                _limboExitCount = nil

                if not v18 then
                  v18 = true
                  notify("- Entered The Limbo: Chat Detection Active -")
                  v17 = "THE LIMBO"
                end
              elseif v18 then
                _limboExitCount = (_limboExitCount or 0) + 1

                if _limboExitCount >= 2 then
                  v18 = false
                  _limboExitCount = nil
                  notify("- Left The Limbo: GUI Detection Active -")
                  v17 = forcedBiome or v426
                end
              elseif forcedBiome then
                local v540 = v429[forcedBiome] or forcedBiome
                local confirmedOk, confirmed = pcall(GYESG.confirmBiome, v40, v540, v426)

                if confirmedOk and confirmed == false then
                  v540 = v17 -- first sighting of an unknown biome name: wait one more scan before learning it
                end

                if v540 ~= v17 then
                  if v17 and v17 ~= v426:upper() and v40[v17] then
                    if not f44(v17) then
                      f33(v17, true)
                    end

                    notify("- Biome ended: " .. v17 .. " -")

                    if addLogConsole then
                      addLogConsole:Log("Biome ended: " .. v17, "WARN")
                    end
                  end

                  if v540 ~= v426:upper() and v40[v540] then
                    if not f44(v540) and not isBiomeInactive(v540) then
                      if v16 then
                        local v541 = v40[v540] or { 5793266, nil, false }
                        local v542 = string.format("%06X", v541[1] or 5793266)

                        enqueueBiomeFound({
                          sessionId = v16,
                          userId = tostring(localPlayer.UserId),
                          username = localPlayer.Name,
                          biomeName = v540,
                          colorHex = v542,
                          imageUrl = v541[2] or nil,
                          isRare = v541[3] or false,
                          timestamp = os.time(),
                        })

                        if v4 then
                          v4 = false
                          flushBiomeBatch()
                        end
                      end

                      f33(v540, false)
                    end

                    if not isBiomeInactive(v540) then
                      f21(v540)
                    end

                    notify("- Biome detected: " .. v540 .. " -")
                    f45(v540)
                  end

                  v17 = v540
                end
              end

              task.wait(math.max(0.1, biomeScanInterval))
            end
          end)

          table.insert(v21, v539)
          v446 = { eden = -math.huge }

          local connect4 = textChatService.MessageReceived:Connect(function(p166)
            if not macroRunning then
              return
            else
              local v543 = p166.TextSource == nil
              local gsub7 = (p166.Text or ""):gsub("<[^>]+>", "")

              local gsub8 = (gsub7:match("^%[(.-)%]%s*") or ""):upper():gsub(
                "%s+", " "
              ):gsub(
                "^%s+", ""
              ):gsub(
                "%s+$", ""
              )

              local gsub9 = gsub7:gsub("^%[.-%]%s*", "")
              local v544 = tick()
              local lower2 = gsub9:lower()

              if string.find(gsub9, "@" .. localPlayer.Name) then
                for index94, value91 in ipairs(v433.ExtractionPatterns) do
                  local v545, v546 = gsub9:match(value91)

                  if v545 then
                    local gsub10 = v545:gsub("%s*,%s*$", ""):gsub("%s+$", "")
                    local v547 = f17(v546)

                    if v547 >= v433.MinimumDetectionThreshold then
                      local v548 = v433.Thumbnails[gsub10]
                      local v549 = f22(gsub10, v547)

                      f28(
                        v547 >= v437 and #v435 > 0 and f40() or "",
                        f20(gsub10, v546, v548, nil, v549), false
                      )

                      notify(
                        "- Aura Detected: " .. gsub10 .. " -", Color3.fromRGB(100, 149, 237)
                      )

                      if addLogConsole then
                        addLogConsole:Log("Aura: " .. gsub10, "INFO")
                      end

                      break
                    end
                  end
                end
              end

              for key28, value92 in pairs(v433.CustomTriggers) do
                local match9 = gsub9:match(key28)

                if match9 then
                  local gsub11 = match9:gsub("^%s*(.-)%s*$", "%1")

                  if string.find(gsub11, localPlayer.Name) or string.find(gsub11, displayName) then
                    local v550 = value92[1]
                    local v551 = value92[2]
                    local v552 = value92[3]
                    local v553 = value92[4]
                    local v554 = f17(v551)

                    if v554 >= v433.MinimumDetectionThreshold then
                      local v555 = f19(gsub11)
                      local v556 = f38(v553:gsub("{nick}%s*", ""):gsub("{rarity}", v551), v555)
                      local v557 = f22(v550, v554)

                      f28(
                        v554 >= v437 and #v435 > 0 and f40() or "",
                        f20(v550, v551, v552, v556, v557), false
                      )

                      notify("- Aura Detected: " .. v550 .. " -", Color3.fromRGB(100, 149, 237))

                      if addLogConsole then
                        addLogConsole:Log("Aura: " .. v550, "INFO")
                      end

                      break
                    end
                  end
                end
              end

              if v543 and v544 > v446.eden and string.find(lower2, "eden")
                and string.find(lower2, "limbo") then
                v446.eden = v544 + 60
                signalEdenSpawn(gsub9)
                f28(f14() and f40("Eden") or "", f24(), false)
                notify("- Eden Spawned in the limbo -")

                if addLogConsole then
                  addLogConsole:Log("Eden spawned in Limbo", "WARN")
                end
              end

              if v18 and v543 then
                local v558 = nil

                if gsub8 ~= "" then
                  local v559 = v429[gsub8] or gsub8

                  if v40[v559] then
                    v558 = v559
                  end
                end

                local v560 = v558
                v560 = v558 or f32(gsub9)

                if v560 then
                  local v561 = v429[v560] or v560

                  if v40[v561] then
                    local lower3 = gsub9:lower()

                    if v430[v561] then
                      local v562 = false

                      for index95, value93 in ipairs(v430[v561]) do
                        if string.find(lower3, value93) then
                          v562 = true
                          break
                        end
                      end

                      if v562 then
                        if v17 == v561 then
                          local v563 = v561 == "GLITCHED" or v561 == "CYBERSPACE"
                            or v561 == "DREAMSPACE" or v561 == "SINGULARITY"

                          f28("", f18(v561, true), v563)
                          notify("- Biome ended: " .. v561 .. " -")

                          if addLogConsole then
                            addLogConsole:Log("Biome ended: " .. v561, "WARN")
                          end

                          v17 = "THE LIMBO"
                        end

                        return
                      end
                    end

                    if v561 ~= v17 then
                      if not isBiomeInactive(v561) then
                        local v564 = v561 == "GLITCHED" or v561 == "CYBERSPACE"
                          or v561 == "DREAMSPACE" or v561 == "SINGULARITY"

                        if v40[v561][3] then
                          f28("@everyone ", f18(v561, false), v564)
                        elseif f15(v561) then
                          f28(f40(v561), f18(v561, false), v564)
                        else
                          f28("", f18(v561, false), v564)
                        end

                        if v16 then
                          local v565 = v40[v561] or { 5793266, nil, false }
                          local v566 = string.format("%06X", v565[1] or 5793266)

                          enqueueBiomeFound({
                            sessionId = v16,
                            userId = tostring(localPlayer.UserId),
                            username = localPlayer.Name,
                            biomeName = v561,
                            colorHex = v566,
                            imageUrl = v565[2] or nil,
                            isRare = v565[3] or false,
                            timestamp = os.time(),
                          })
                        end

                        f21(v561)
                      end

                      notify("- Biome detected: " .. v561 .. " -")
                      v17 = v561
                      f45(v561)
                    end

                    return
                  end

                  return
                end

                return
              end

              return
            end
          end)

          table.insert(v20, connect4)
          return
        end
      end
    end

    function performMacroStop()
      if not macroRunning then
        return
      end

      macroRunning = false
      getgenv().MacroRunning = false
      userConfig.WasMacroRunning = false

      if v33 then
        pcall(v33)
        v33 = nil
        task.wait(1)
      end

      v34 = false
      CleanupMacro()
      SaveData()
      notify("- Macro Stopped -", Color3.fromRGB(255, 100, 100))

      if addStatusBadge2 then
        addStatusBadge2:SetState("offline")
      end

      if addStatusBadge22 then
        addStatusBadge22:SetState("offline")
      end

      pcall(function() ui:SetSidebarUserStatus(false) end)

      if v49 then
        ui:SetMetricValue(v49, "00:00:00")
      end

      if addLogConsole then
        addLogConsole:Log("Macro stopped", "ERROR")
      end

      if v55 then
        v55:SetEnabled(true)
      end

      if v56 then
        v56:SetEnabled(false)
      end
    end

    function v36()
      performMacroStop()
    end

    function v38()
      if macroRunning then
        return
      elseif _G.__BIOME_SUSPENDED then
        errorNotify("- Error: Your account is suspended from using this script! -")

        if _G.__BIOME_SUSPENDED_REASON then
          notify(
            "- Reason: " .. tostring(_G.__BIOME_SUSPENDED_REASON) .. " -",
            Color3.fromRGB(255, 165, 0)
          )
        end

        return
      elseif userConfig.Webhook == "" then
        errorNotify("- Error: No Webhook configured! -")
        return
      elseif #extractWebhooks(userConfig.Webhook) == 0 then
        errorNotify("- Error: Invalid Webhook URL! -")
        return
      else
        if userConfig.PSLink == "" then
          notify("- No Private Server Link configured! -", Color3.fromRGB(255, 200, 80))
        elseif userConfig.PSLink:lower():find("roblox.com/share")
          or userConfig.PSLink:lower():find("share?code=") then
          notify(
            "- Use a Permanent Server Link, not a share link -", Color3.fromRGB(255, 200, 80)
          )
        end

        CleanupMacro()
        v15 = false
        v34 = false
        _G.__BIOME_SENT_HASHES = {}

        v12.BiomeCount = 0
        v12.MerchantCount = 0
        v12.StartTick = os.time()

        v17 = nil
        v18 = false
        v19 = false
        v33 = nil
        macroRunning = true
        getgenv().MacroRunning = true
        userConfig.WasMacroRunning = true
        SaveData()
        notify("- Macro Started -", Color3.fromRGB(100, 220, 100))

        if addStatusBadge2 then
          addStatusBadge2:SetState("online")
        end

        if addStatusBadge22 then
          addStatusBadge22:SetState("online")
        end

        pcall(function() ui:SetSidebarUserStatus(true) end)

        if addLogConsole then
          addLogConsole:Log("Macro started", "SUCCESS")
        end

        if v55 then
          v55:SetEnabled(false)
        end

        if v56 then
          v56:SetEnabled(true)
        end

        v16 = "SES-" .. tostring(math.random(100000, 999999)) .. "-" .. tostring(os.time())

        local v567 = enqueueDashboardEvent

        v567("/webhook/session-start", {
          sessionId = v16,
          userId = tostring(localPlayer.UserId),
          username = localPlayer.Name,
          scriptVersion = v39,
          timestamp = os.time(),
          metadata = {
            webhook_urls = userConfig.Webhook or "",
            discord_ids = userConfig.DiscordId or "",
            role_ids = userConfig.RoleId or "",
            ps_link = userConfig.PSLink or "",
          },
        })

        task.spawn(MainLogic)
        return
      end
    end

    function v37()
      if _G.__BIOME_SCRIPT_UNLOADING then
        return
      end

      _G.__BIOME_SCRIPT_UNLOADING = true
      macroRunning = false
      getgenv().MacroRunning = false
      pcall(function() ui:SetSidebarUserStatus(false) end)

      autoWalk.enabled = false
      autoWalk.runId = 0
      autoWalk.currentTask = nil
      autoWalk.currentTarget = nil

      v63.running = false

      if v33 then
        pcall(v33)
        v33 = nil
      end

      pcall(function() inputHelper.restoreCamera() end)

      pcall(function()
        local v568 = rawget(_G, "__AF")

        if v568 then
          v568.fishingActive = false
          v568.scbrActive = false
          v568.autoSellActive = false
          v568.scbrOnlyRunning = false
          v568.isSelling = false
          v568.isUsingSCBR = false

          if v568.stopHB then
            v568.stopHB()
          end

          if v568.closeInventory then
            v568.closeInventory()
          end
        end
      end)

      pcall(function()
        if biomeNotifSystem.Gui and biomeNotifSystem.Gui.Parent then
          biomeNotifSystem.Gui:Destroy()
        end

        biomeNotifSystem.Gui = nil
        biomeNotifSystem.Active = {}
      end)

      _G.__BIOME_SCRIPT_EXECUTED = false
      _G.__BIOME_SCRIPT_LOADING = false
      _G.__BIOME_SCRIPT_UNLOADING = false
      _G.__BiomeNotifSystem = nil
      _G.__AF = nil

      function v16224()
        ui:Destroy()
      end
    end

    if v55 and v55.Button then
      v55.Button.Activated:Connect(function() v38() end)
    end

    if v56 and v56.Button then
      v56.Button.Activated:Connect(function() v36() end)
    end

    _G.__BIOME_SCRIPT_LOADING = false
    _G.__BIOME_SCRIPT_EXECUTED = true

    v67 = 0

    textChatService.MessageReceived:Connect(function(p167)
      local gsub12 = (p167.Text or ""):gsub("<[^>]->", ""):gsub("^%[.-%]%s*", "")
      local lower4 = gsub12:lower()

      if tick() > v67 and lower4:find("eden", 1, true) and lower4:find("limbo", 1, true) then
        v67 = tick() + 60
        signalEdenSpawn(gsub12)
      end
    end)

    function isLocalMessage(p168)
      if p168.TextSource then
        return p168.TextSource.UserId == localPlayer.UserId
      end

      return false
    end

    textChatService.MessageReceived:Connect(function(p169)
      local v569

      if not isLocalMessage(p169) then
        return
      else
        local gsub13 = (p169.Text or ""):gsub("<[^>]->", ""):gsub("^%[.-%]%s*", "")

        if gsub13 == "" then
          return
        else
          local v570, v571 = gsub13:match("^/(%w+)%s*(.*)")

          if not v570 then
            return
          else
            local lower5 = v570:lower()

            if lower5 == "test" then
              if v35 then
                v35()
              else
                notify(
                  "- /test: Script still loading, please wait -", Color3.fromRGB(255, 165, 0)
                )
              end
            elseif lower5 == "start" then
              if not macroRunning then
                notify("- /start: Macro Starting -", Color3.fromRGB(100, 220, 100))
                v38()
              else
                notify("- /start: Macro already running -", Color3.fromRGB(255, 165, 0))
              end
            elseif lower5 == "stop" then
              notify("- /stop: Macro Stopped -", Color3.fromRGB(255, 100, 100))
              v36()
            elseif lower5 == "ping" then
              v569 = tonumber(v571:match("^%s*(%d+)"))

              if v569 then
                userConfig.PingThreshold = v569
                SaveData()

                if addInputNumber then
                  pcall(function() addInputNumber:Set(v569) end)
                end

                notify(
                  string.format("- /ping: Threshold set to %d -", v569),
                  Color3.fromRGB(100, 220, 100)
                )
              else
                notify(
                  "- /ping: use the UI input to set the threshold -",
                  Color3.fromRGB(255, 165, 0)
                )
              end
            elseif lower5:match("^id%d+$") then
              local v572 = tonumber(lower5:match("%d+"))
              local sD = v571:match("^%s*(%d+)")

              if v572 and sD and v572 >= 1 then
                setDiscordId(v572, sD)
                SaveData()

                if addInput3 then
                  pcall(function() addInput3:Set(userConfig.DiscordId) end)
                end

                notify(
                  string.format("- /id%d set to %s -", v572, sD), Color3.fromRGB(100, 220, 100)
                )
              end
            end

            return
          end
        end
      end
    end)

    bootStep("Mounting settings controls", 0.72, "settings page")

    ui:AddSectionHeader(
      6, "Settings", "Advanced macro behavior, notification filters, and collection system"
    )

    -- GYESG: language, UI colour, walking and FPS options
    ui:AddDivider(6, "LANGUAGE / ภาษา")

    ui:AddDropdown(
      6, "Language / ภาษา",
      userConfig.Language == "th" and { "ไทย (Thai)", "English" } or { "English", "ไทย (Thai)" },
      function(choice) GYESG.setLanguage(choice) end
    )

    ui:AddLabel(6, "Most texts change right away; the rest update on the next run.", "muted")

    ui:AddDivider(6, "UI COLOR")

    ui:AddDropdown(6, "Theme color", { "Default", "Blue", "Purple", "Pink", "Red", "Orange", "Yellow", "Green", "Cyan", "White" },
      function(choice) GYESG.pickPreset(choice) end)

    ui:AddInput(6, "Custom color (HEX)", userConfig.UiColor or "#3B82F6", function(text)
      if type(text) == "string" and text ~= "" and text ~= userConfig.UiColor then
        GYESG.setUiColor(text)
      end
    end)

    ui:AddDivider(6, "WALKING & PERFORMANCE")

    ui:AddToggle(6, "Fast Walk (smart paths)", userConfig.FastWalk ~= false, function(value)
      userConfig.FastWalk = value
      SaveData()
    end, "Fewer path searches and straighter routes, so the character walks faster")

    ui:AddToggle(6, "FPS Boost (lower graphics)", userConfig.FpsBoost == true, function(value)
      userConfig.FpsBoost = value
      SaveData()
      GYESG.setFpsBoost(value)
    end, "Lowers quality, shadows and particle effects to reduce lag. Turn off to restore.")

    if userConfig.FpsBoost == true then
      task.defer(function() GYESG.setFpsBoost(true) end)
    end

    ui:AddDivider(6, "PERFORMANCE")

    addInputNumber2 = ui:AddInputNumber(6, "Biome Scanner Interval (Seconds)", { Min = 0.1, Max = 5, Placeholder = "0.5" }, function(biomeScanInterval2)
      userConfig.BiomeScanInterval = biomeScanInterval2
      SaveData()
    end)

    ui:AddAlert(
      6, "Performance Warning",
      "Increasing this interval significantly reduces CPU usage and lag on low-end devices or phones, but may cause a slight delay in detecting new biomes.",
      "warning"
    )

    ui:AddDivider(6, "DISCORD & ANTI-SPAM")

    local v573 = {}

    for key29, value94 in pairs(v40) do
      local v574 = false

      for index96, value95 in ipairs(v41) do
        if key29 == value95 then
          v574 = true
          break
        end
      end

      if not v574 and not isBiomeInactive(key29) then
        v573[#v573 + 1] = key29
      end
    end

    table.sort(v573)

    addMultiSelect = ui:AddMultiSelect(6, "Muted Biomes", v573, function(p170)
      userConfig.MutedBiomes = {}

      for key30, value96 in pairs(p170) do
        if value96 then
          userConfig.MutedBiomes[key30] = true
        end
      end

      SaveData()
    end)

    ui:AddLabel(
      6, "Muted biomes are still counted in stats but won't send Discord notifications.",
      "muted"
    )

    ui:AddDivider(6, "AUTO EXECUTE")

    ui:AddToggle(6, "Auto Execute", userConfig.AutoExecute == true, function(p171)
      userConfig.AutoExecute = p171

      if not p171 then
        userConfig.WasMacroRunning = false
      end

      SaveData()

      if p171 then
        QueueAutoExecute()
      end
    end, "Queues this script to run again after teleport or rejoin")

    ui:AddAlert(
      6, "Resumes Last State",
      "When the script reruns via Auto Execute, it automatically returns to whatever state it was last in (e.g. if Start was active on the last teleport, it starts again automatically).",
      "info"
    )

    ui:AddDivider(6, "ANTI-AFK")

    addInputNumber3 = ui:AddInputNumber(6, "Execution Interval (Seconds)", { Min = 30, Max = 1140, Placeholder = "300" }, function(antiAfkInterval2)
      userConfig.AntiAfkInterval = antiAfkInterval2
      SaveData()
    end)

    ui:AddDivider(6, "AUTOMATION PATHFINDING")

    addToggle2 = ui:AddToggle(6, "Debug Pathfinding", userConfig.PathDebug, function(p172)
      userConfig.PathDebug = p172

      if not p172 then
        clearPathDebug(false)
      end

      updateWorldAutomationMetrics()
      SaveData()
    end, "Shows only the active path line and waypoints while navigation is running")

    ui:AddAlert(
      6, "Pathfinding Warning",
      "Debug path objects are created locally in Workspace and are cleared as the character advances.",
      "warning"
    )

    bootStep("Integrating fishing automation", 0.84, "automation page")
    _G.__AF = {}

    af = _G.__AF
    af.inset = guiService:GetGuiInset()
    af.FISHING_POS = Vector3.new(65.158897, 97.000015, -294.892029)
    af.NPC_POS = Vector3.new(96.409035, 104.5, -296.447571)

    af.ITEMS = {
      { Name = "Biome Randomizer", Amount = 1, Priority = 1 },
      { Name = "Strange Controller", Amount = 1, Priority = 2 },
    }

    af.ARRIVE_DIST = 4
    af.STUCK_TIMEOUT = 1.5
    af.STUCK_MIN_MOVE = 0.5
    af.MAX_RECALC = 8
    af.WALK_TIMEOUT = 60
    af.LOG_MAX = 6
    af.fishingActive = false
    af.autoSellActive = userConfig.AutoSellActive or false
    af.scbrActive = false
    af.isSelling = false
    af.isUsingSCBR = false
    af.scbrDispatched = false
    af.scbrOnlyRunning = false
    af.fishCount = 0
    af.targetFishCount = userConfig.AutoFishTarget or 20
    af.scbrTimer = 0
    af.scbrIntervalMins = userConfig.AutoFishSCBRMins or 5
    af.fishAtLastSCBR = 0
    af.lastSCBRUseAt = 0
    af.state = "idle"
    af.fishCountAtSellCheck = 0
    af.fishCountCheckStartAt = 0
    af.heartbeatConn = nil
    af.MainUI = nil
    af.Inventory = nil
    af.ItemGrid = nil
    af.logLines = {}
    af.forceResetCast = false
    af.forceSellNow = false
    af.metricDirty = false
    af.lastFishCaughtAt = 0
    af.lastFishProgressAt = 0
    af._scbrParallelThread = nil
    af.FishCountMetricRef = nil
    af.StatusLogRef = nil
    af.SCBRTimerMetricRef = nil
    af.FishStatusMetricRef = nil

    function af.log(p173)
      table.insert(af.logLines, p173)

      if #af.logLines > af.LOG_MAX then
        table.remove(af.logLines, 1)
      end

      if af.StatusLogRef then
        pcall(function() af.StatusLogRef:Log(p173, "INFO") end)
      end
    end

    function af.logWarn(p174)
      table.insert(af.logLines, "[!] " .. p174)

      if #af.logLines > af.LOG_MAX then
        table.remove(af.logLines, 1)
      end

      if af.StatusLogRef then
        pcall(function() af.StatusLogRef:Log(p174, "WARN") end)
      end
    end

    function af.updateFishMetric()
      if af.FishCountMetricRef then
        pcall(function()
          local v575

          if af.autoSellActive then
            v575 = string.format("%d / %d", af.fishCount, af.targetFishCount)
          else
            v575 = tostring(af.fishCount)
          end

          ui:SetMetricValue(af.FishCountMetricRef, v575)
        end)
      end

      if af.FishStatusMetricRef then
        pcall(function()
          local v576 = {}

          if af.fishingActive then
            v576[#v576 + 1] = "Fishing"

            if af.autoSellActive then
              v576[#v576 + 1] = "AutoSell"
            end
          end

          if af.scbrActive then
            v576[#v576 + 1] = "SC/BR"
          end

          if af.isSelling then
            v576[#v576 + 1] = "->Selling"
          end

          if af.isUsingSCBR then
            v576[#v576 + 1] = "->SC/BR"
          end

          ui:SetMetricValue(
            af.FishStatusMetricRef, #v576 > 0 and table.concat(v576, " * ") or "Idle"
          )
        end)
      end

      if af.SCBRTimerMetricRef then
        pcall(function()
          if af.scbrActive then
            local v577 = math.max(0, af.scbrTimer)
            local v578 = math.floor(v577 / 60)
            ui:SetMetricValue(af.SCBRTimerMetricRef, string.format("%d:%02d", v578, v577 % 60))
          else
            ui:SetMetricValue(af.SCBRTimerMetricRef, "--")
          end
        end)
      end
    end

    function af.pressEnter()
      virtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
      task.wait()
      virtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
    end

    function af.activate(p175)
      guiService.SelectedObject = p175
      task.wait()

      if guiService.SelectedObject ~= p175 or not p175.Parent then
        guiService.SelectedObject = nil
        return false
      end

      af.pressEnter()
      return true
    end

    v68 = 0

    function af.navActivate(p176)
      if not p176 then
        return false
      else
        local v579 = tick()

        if v579 - v68 < 0.08 then
          task.wait(0.08 - (v579 - v68))
        end

        if not p176 or not p176.Parent then
          return false
        end

        guiService.SelectedObject = nil
        task.wait(0.03)
        p176.Selectable = true
        guiService.SelectedObject = p176
        task.wait(0.06)

        if guiService.SelectedObject ~= p176 then
          guiService.SelectedObject = nil
          return false
        elseif not p176.Parent then
          guiService.SelectedObject = nil
          return false
        else
          virtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
          task.wait(0.03)
          virtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
          task.wait(0.06)
          guiService.SelectedObject = nil
          v68 = tick()
          return true
        end
      end
    end

    function af.vimClick(p177, p178)
      inputHelper.clickAt(p177, p178)
    end

    function af.ghostClick()
      virtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
      task.wait(0.015)
      virtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end

    function af.smartClick(p179, p180, p181)
      return inputHelper.activateGuiObject(p179, p180, p181 or 4)
    end

    function af.findRootIL()
      local mainInterface5 = playerGui:FindFirstChild("MainInterface")

      if not mainInterface5 then
        return nil
      end

      for index97, value97 in ipairs(mainInterface5:GetChildren()) do
        if value97:IsA("ImageLabel") then
          local count7 = 0

          for index98, value98 in ipairs(value97:GetChildren()) do
            if value98:IsA("ImageLabel") then
              count7 = count7 + 1
            end
          end

          if count7 == 5 then
            return value97
          end
        end
      end
    end

    function af.findInfoIL(p182)
      for index99, value99 in ipairs(p182:GetChildren()) do
        if value99:IsA("ImageLabel") then
          local count8 = 0
          local count9 = 0

          for index100, value100 in ipairs(value99:GetChildren()) do
            if value100:IsA("ImageLabel") then
              count9 = count9 + 1
            end

            if value100:IsA("TextLabel") then
              count8 = count8 + 1
            end
          end

          if count9 == 2 and count8 == 4 then
            return value99
          end
        end
      end
    end

    function af.findBtnIL(p183)
      for index101, value101 in ipairs(p183:GetChildren()) do
        if value101:IsA("ImageLabel") then
          local count10 = 0

          for index102, value102 in ipairs(value101:GetChildren()) do
            if value102:IsA("ImageButton") then
              count10 = count10 + 1
            end
          end

          if count10 == 4 then
            return value101
          end
        end
      end
    end

    function af.findCastButton(p184)
      for index103, value103 in ipairs(p184:GetChildren()) do
        if value103:IsA("ImageButton") then
          local findFirstChildWhichIsA6 = value103:FindFirstChildWhichIsA("TextLabel", true)

          if findFirstChildWhichIsA6 and findFirstChildWhichIsA6.Text == "Fish" then
            return value103
          end
        end
      end
    end

    function af.findExitCastButton(p185)
      for index104, value104 in ipairs(p185:GetChildren()) do
        if value104:IsA("ImageButton") then
          local findFirstChildWhichIsA7 = value104:FindFirstChildWhichIsA("TextLabel", true)

          if findFirstChildWhichIsA7 and findFirstChildWhichIsA7.Text == "" then
            return value104
          end
        end
      end

      return nil
    end

    function af.isActivelyFishing()
      local v580 = af.findRootIL()

      if not v580 then
        return false
      elseif v580.BackgroundTransparency >= 1 then
        return false
      elseif not v580.Visible then
        return false
      else
        local v581 = af.findInfoIL(v580)

        if not v581 then
          return false
        else
          local v582 = af.findBtnIL(v581)

          if not v582 then
            return false
          else
            local v583 = af.findCastButton(v582)

            if v583 and not v583.Visible then
              return false
            end

            return v583 ~= nil
          end
        end
      end
    end

    function af.findCloseButton(p186)
      for index105, value105 in ipairs(p186:GetChildren()) do
        if value105:IsA("ImageLabel") then
          local count11 = 0
          local count12 = 0
          local count13 = 0
          local count14 = 0

          for index106, value106 in ipairs(value105:GetChildren()) do
            if value106:IsA("ImageLabel") then
              count13 = count13 + 1
            end

            if value106:IsA("TextLabel") then
              count11 = count11 + 1
            end

            if value106:IsA("ScrollingFrame") then
              count14 = count14 + 1
            end

            if value106:IsA("ImageButton") then
              count12 = count12 + 1
            end
          end

          if count13 == 2 and count11 == 1 and count14 == 1 and count12 == 1 then
            for index107, value107 in ipairs(value105:GetChildren()) do
              if value107:IsA("ImageButton") then
                return value107
              end
            end
          end
        end
      end
    end

    function af.resolveUI()
      local v584 = af.findRootIL()

      if not v584 then
        return nil
      else
        local v585 = af.findInfoIL(v584)

        if not v585 then
          return nil
        else
          local v586 = af.findBtnIL(v585)

          if not v586 then
            return nil
          end

          return { rootIL = v584, infoIL = v585, btnIL = v586 }
        end
      end
    end

    function af.tryClose(p187, p188)
      local v587 = p188 or 3
      local v588 = af.findCloseButton(p187.rootIL)

      if not v588 then
        return false
      end

      for i18 = 1, v587 do
        guiService.SelectedObject = nil
        task.wait(0.2)
        v588.Selectable = true
        guiService.SelectedObject = v588
        task.wait(0.2)

        if guiService.SelectedObject ~= v588 then
          guiService.SelectedObject = nil
        else
          virtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
          task.wait(0.1)
          virtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
          guiService.SelectedObject = nil
          task.wait(0.3)

          if not v588.Parent or not v588.Parent.Parent then
            return true
          elseif not af.findRootIL() then
            return true
          end
        end
      end

      af.smartClick(v588, function()
        return not v588.Parent or not v588.Parent.Parent or not af.findRootIL()
      end, 2)

      task.wait(0.3)
      return true
    end

    function af.findMiniPanel(p189)
      return p189:GetChildren()[5] or nil
    end

    function af.findInnerIL(p190)
      local v589 = af.findMiniPanel(p190)

      if not v589 then
        return nil
      else
        local v590, v591 = pcall(function()
          return v589:GetChildren()[3]:FindFirstChildWhichIsA("ImageLabel")
        end)

        return v590 and v591 or nil
      end
    end

    function af.findBar(p191)
      local v592 = af.findInnerIL(p191)

      if not v592 then
        return nil
      else
        local v593, v594 = pcall(function() return v592:GetChildren()[3] end)
        return v593 and v594 or nil
      end
    end

    function af.findRect(p192)
      local v595 = af.findInnerIL(p192)

      if not v595 then
        return nil
      else
        local v596, v597 = pcall(function() return v595:FindFirstChildWhichIsA("ImageLabel") end)
        return v596 and v597 or nil
      end
    end

    function af.findTimerLabel(p193)
      local v598 = af.findMiniPanel(p193)

      if not v598 then
        return nil
      else
        local v599, v600 = pcall(function()
          return v598:GetChildren()[3].ImageLabel:FindFirstChildWhichIsA("TextLabel")
        end)

        return v599 and v600 or nil
      end
    end

    function af.isReady(p194)
      return p194 and p194.Text == "Ready!"
    end

    function af.isFinished(p195)
      if not p195 then
        return true
      else
        local v601 = tonumber((p195.Text:match("^%s*(.-)%s*$")))

        if v601 ~= nil then
          return v601 <= 0.1
        end

        return false
      end
    end

    function af.stopHB()
      if af.heartbeatConn then
        af.heartbeatConn:Disconnect()
        af.heartbeatConn = nil
      end
    end

    function af.runMinigame(p196)
      local v602 = 12
      local total4 = 0
      local count15 = 0
      local v603 = false
      local v604 = false
      local v605 = 0
      local v606 = tick()
      local v607 = false
      local v608 = 0
      af.stopHB()
      local v609 = af.findBar(p196.rootIL)
      local v610 = af.findRect(p196.rootIL)
      local v611 = af.findTimerLabel(p196.rootIL)
      local v612 = af.findMiniPanel(p196.rootIL)

      local v613 = task.spawn(function()
        while af.fishingActive and not v604 do
          task.wait(0.5)

          if v604 then
            break
          end

          v609 = af.findBar(p196.rootIL)
          v610 = af.findRect(p196.rootIL)
          v611 = af.findTimerLabel(p196.rootIL)
          v612 = af.findMiniPanel(p196.rootIL)
        end
      end)

      local v614

      af.heartbeatConn = runService.Heartbeat:Connect(function()
        if v604 or not af.fishingActive then
          af.stopHB()
          pcall(function() task.cancel(v613) end)
          return
        elseif tick() - v606 > 35 then
          v604 = true

          af.logWarn("Minigame timeout -- forcing close")
          af.stopHB()

          pcall(function() task.cancel(v613) end)
          return
        else
          local v615 = v609
          local v616 = v610
          local v617 = v611
          local v618 = not v615
          local v619 = v612

          if v618 or not v616 or not v619 or not v619.Visible then
            v608 = v608 + 1

            if v608 >= 3 then
              v604 = true
              af.log("Minigame panel closed")
              af.stopHB()
            end

            return
          end

          v608 = 0

          if af.isFinished(v617) then
            v604 = true
            v607 = true

            af.log("Timer zeroed -- closing panel")
            af.stopHB()

            af._postMinigameSpawn = task.spawn(function()
              task.wait(0.7)

              if af.isSelling or af.state == "selling" then
                return
              else
                local v620 = tick()
                local v621 = false

                while af.fishingActive and tick() - v620 < 6 do
                  if af.isSelling or af.state == "selling" then
                    break
                  else
                    local v622 = af.resolveUI()

                    if not v622 then
                      break
                    else
                      local v623 = af.findCastButton(v622.btnIL)

                      if v623 and v623.Visible then
                        break
                      end

                      if not v621 then
                        local v624 = af.findCloseButton(v622.rootIL)

                        if v624 then
                          af.navActivate(v624)
                          v621 = true
                        end
                      end

                      task.wait(0.1)
                    end
                  end
                end

                af._postMinigameSpawn = nil
                return
              end
            end)

            return
          else
            local v625 = v615.AbsolutePosition.X + v615.AbsoluteSize.X
            local x = v616.AbsolutePosition.X
            local v626 = tick()

            if v603 and v614 ~= nil then
              local v627 = v625 - v614

              if v627 > 1 then
                count15 = count15 + 1
                total4 = total4 + (v627 - total4) / count15
                v602 = math.clamp(total4 * 0.4, 6, 40)
                v603 = false
                v614 = nil
              end
            end

            if v626 - v605 < 0.18 then
              return
            end

            if v625 < x - 2 or v625 <= x + v602 and v625 >= x - 2 then
              v614 = v625
              v603 = true
              af.ghostClick()
              v605 = v626
            end

            return
          end
        end
      end)

      while not v604 and af.fishingActive do
        task.wait(0.1)
      end

      af.stopHB()
      return v607
    end

    function af.getCharParts()
      local character5 = localPlayer.Character

      if not character5 then
        localPlayer.CharacterAdded:Wait()
        character5 = localPlayer.Character
      end

      return character5, character5:WaitForChild("Humanoid", 5), (character5:WaitForChild("HumanoidRootPart", 5))
    end

    af.navRunId = 0

    function af.walkTo(p197)
      local v628, v629, v630 = af.getCharParts()
      local navRunId

      if not v629 or not v630 then
        af.logWarn("walkTo: character not found")
        return false
      elseif v629.Health <= 0 then
        return false
      else
        af.navRunId = af.navRunId + 1
        navRunId = af.navRunId

        local function f47()
          return (af.fishingActive or af.scbrOnlyRunning or af.isSelling or af.isUsingSCBR)
            and navRunId == af.navRunId
        end

        local v631 = tick()

        while f47() and tick() - v631 < af.WALK_TIMEOUT do
          local v632, v633, v634 = af.getCharParts()

          if not v634 then
            return false
          elseif (p197 - v634.Position).Magnitude < af.ARRIVE_DIST then
            af.log("walkTo: arrived")
            return true
          else
            local v635, v636 = moveWithPathfinding(p197, {
              TaskName = "fishing",
              IsActive = f47,
            })

            if v635 then
              local v637, v638, v639 = af.getCharParts()

              if v639 and (p197 - v639.Position).Magnitude < af.ARRIVE_DIST + 3 then
                af.log("walkTo: arrived")
                return true
              end
            else
              af.logWarn("walkTo: path failed - " .. tostring(v636))
              task.wait(0.5)
            end
          end
        end

        af.logWarn("walkTo: failed to reach destination")
        return false
      end
    end

    function af.forceLookAtNPC()
      local currentCamera4 = workspace.CurrentCamera
      local v640, v641, v642 = af.getCharParts()

      if not v642 then
        return
      end

      pcall(function()
        currentCamera4.CameraType = Enum.CameraType.Scriptable

        v642.CFrame = CFrame.new(
          v642.Position, Vector3.new(af.NPC_POS.X, v642.Position.Y, af.NPC_POS.Z)
        )

        currentCamera4.CFrame = CFrame.new(v642.Position + Vector3.new(0, 2, 0), af.NPC_POS)
        runService.RenderStepped:Wait()
      end)

      currentCamera4.CameraType = Enum.CameraType.Custom
    end

    function f7()
      return inputHelper.findDialogChoices()
    end

    function af.interactUntilSellFish()
      af.log("Opening NPC sell dialog...")
      af.forceLookAtNPC()

      task.wait(0.3)
      local v643 = tick()
      local v644 = -999
      local count16 = 0

      while af.fishingActive and tick() - v643 < 25 do
        if tick() - v644 >= 0.6 then
          virtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
          task.wait(0.12)
          virtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
          v644 = tick()
          count16 = count16 + 1

          if count16 % 3 == 0 then
            af.logWarn("Adjusting camera for NPC")
            af.forceLookAtNPC()
          end
        end

        local v645 = f7()

        if v645 then
          for index108, value108 in ipairs(v645:GetChildren()) do
            local v646 = value108

            if v646:IsA("TextButton") then
              local lower6 = v646.Text:lower()

              if lower6:find("sell") and lower6:find("fish") then
                af.log("Found 'Sell Fish' -- clicking")
                af.navActivate(v646)

                task.wait(0.2)

                if not v646.Parent or not v646.Visible then
                  return true
                end

                af.smartClick(
                  v646, function() return not v646.Parent or not v646.Visible end, 3
                )

                task.wait(0.15)
                return true
              end
            end
          end
        end

        task.wait(0.1)
      end

      af.logWarn("NPC interact timeout -- sell dialog never appeared")
      return false
    end

    function af.interactNPC()
      return true
    end

    function af.handleDialog()
      return true
    end

    function af.setupFishingFrame()
      local mainInterface6 = playerGui:FindFirstChild("MainInterface")

      if not mainInterface6 then
        return false
      end

      if mainInterface6:FindFirstChild("Fishing") then
        return true
      end

      for index109, fishing in ipairs(mainInterface6:GetChildren()) do
        if fishing:IsA("Frame") then
          local count17 = 0
          local count18 = 0
          local count19 = 0
          local count20 = 0

          for index110, value109 in ipairs(fishing:GetChildren()) do
            if value109:IsA("UIStroke") then
              count19 = count19 + 1
            end

            if value109:IsA("Frame") then
              count20 = count20 + 1
            end

            if value109:IsA("ImageButton") then
              count18 = count18 + 1
            end

            if value109:IsA("TextLabel") then
              count17 = count17 + 1
            end
          end

          if count19 == 1 and count20 == 3 and count18 == 2 and count17 == 1 then
            fishing.Name = "Fishing"
            return true
          end
        end
      end

      return false
    end

    function af.findFishScrollingFrame(p198)
      for index111, value110 in ipairs(p198:GetDescendants()) do
        if value110:IsA("ScrollingFrame") then
          if value110:FindFirstChildOfClass("UIListLayout") then
            local v647 = false

            for index112, value111 in ipairs(value110:GetChildren()) do
              if value111:IsA("ImageButton") then
                v647 = true
                break
              end
            end

            if not v647 then
              return value110
            end
          end
        end
      end

      return nil
    end

    function af.findSellAllButton(p199)
      for index113, value112 in ipairs(p199:GetDescendants()) do
        if value112:IsA("TextLabel") and value112.Text == "Sell All" then
          if value112.Parent and value112.Parent:IsA("ImageButton") then
            return value112.Parent
          end
        end
      end

      return nil
    end

    function af.findConfirmSellButton(p200)
      for index114, value113 in ipairs(p200:GetChildren()) do
        if value113:IsA("ImageButton") then
          local canvasGroup = value113:FindFirstChildOfClass("CanvasGroup")

          if canvasGroup then
            for index115, value114 in ipairs(canvasGroup:GetChildren()) do
              if value114:IsA("Frame") then
                for index116, value115 in ipairs(value114:GetChildren()) do
                  if value115:IsA("Frame") then
                    local count21 = 0

                    for index117, value116 in ipairs(value115:GetChildren()) do
                      if value116:IsA("ImageButton") then
                        count21 = count21 + 1
                      end
                    end

                    if count21 == 2 then
                      for index118, value117 in ipairs(value115:GetChildren()) do
                        if value117:IsA("ImageButton") then
                          local textLabel2 = value117:FindFirstChildOfClass("TextLabel")

                          if textLabel2 and textLabel2.Text == "Sell" then
                            return value117
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end

      return nil
    end

    function af.closeFishingMenu(p201)
      for index119, value118 in ipairs(p201:GetChildren()) do
        if value118:IsA("TextLabel") then
          local imageButton = value118:FindFirstChildOfClass("ImageButton")

          if imageButton then
            af.navActivate(imageButton)
            task.wait(0.25)
            return true
          end
        end
      end

      local findFirstChild8 = p201:FindFirstChild("Close", true)

      local findFirstChild9 = findFirstChild8
      findFirstChild9 = findFirstChild8 or p201:FindFirstChild("Exit", true)

      if findFirstChild9 and findFirstChild9:IsA("ImageButton") then
        af.navActivate(findFirstChild9)
        task.wait(0.5)
        return true
      end

      return false
    end

    function af.executeAutoSell()
      af.isSelling = true
      local v648 = true
      local v649 = tick() + 300
      local v650 = 0

      local function f48(p202)
        local count22 = 0

        for index120, value119 in ipairs(p202:GetChildren()) do
          if value119:IsA("Frame") and value119:FindFirstChildOfClass("ImageButton") then
            count22 = count22 + 1
          end
        end

        return count22
      end

      if not af.setupFishingFrame() then
        af.logWarn("Fishing frame not found ? cannot sell")
        af.isSelling = false
        return false
      else
        local mainInterface7 = playerGui:FindFirstChild("MainInterface")
        local fishing2 = mainInterface7 and mainInterface7:FindFirstChild("Fishing")

        if not fishing2 then
          af.logWarn("Fishing frame vanished after setup")
          af.isSelling = false
          return false
        else
          local v651 = tick() + 10

          while tick() < v651 do
            if not af.isSelling then
              af.isSelling = false
              return false
            end

            if fishing2.Visible then
              break
            end

            task.wait(0.1)
          end

          task.wait(0.1)
          local v652 = af.findFishScrollingFrame(fishing2)

          if not v652 then
            af.logWarn("Fish SF not found")
            af.isSelling = false
            return false
          else
            local v653 = af.findSellAllButton(fishing2)

            if not v653 then
              af.logWarn("Sell All btn not found")
              af.isSelling = false
              return false
            else
              local v654 = f48(v652)
              af.log("Starting sell. Fish count: " .. v654)

              while v648 and tick() < v649 do
                task.wait(0.05)
                local v655 = nil

                for index121, value120 in ipairs(v652:GetChildren()) do
                  if value120:IsA("Frame") and value120:FindFirstChildOfClass("ImageButton") then
                    v655 = value120
                    break
                  end
                end

                if not v655 then
                  af.log("All fish sold!")
                  break
                else
                  local imageButton2 = v655:FindFirstChildOfClass("ImageButton")

                  if imageButton2 then
                    if imageButton2.Visible and imageButton2.AbsoluteSize.Magnitude > 0 then
                      af.navActivate(imageButton2)
                      task.wait(0.06)
                    else
                      task.wait(0.05)
                    end
                  end

                  if not v653.Parent then
                    af.logWarn("Sell All btn disappeared ? re-finding")
                    v653 = af.findSellAllButton(fishing2)

                    if not v653 then
                      af.logWarn("Sell All btn lost ? aborting")
                      break
                    end
                  end

                  if v653.Visible and v653.AbsoluteSize.Magnitude > 0 then
                    task.wait(0.05)
                    af.navActivate(v653)
                    task.wait(0.08)
                    local v656 = false
                    local v657 = tick() + 5

                    while tick() < v657 and not v656 and v648 do
                      task.wait(0.03)
                      local v658 = af.findConfirmSellButton(fishing2)

                      if v658 and v658.Visible and v658.AbsoluteSize.Magnitude > 0 then
                        task.wait(0.05)
                        af.navActivate(v658)
                        task.wait(0.05)
                        local v659 = v655
                        local v660 = tick() + 2

                        while tick() < v660 do
                          if not v659.Parent then
                            v656 = true
                            break
                          end

                          task.wait(0.05)
                        end

                        if v656 then
                          local v661 = f48(v652)

                          if v661 == v654 then
                            v650 = v650 + 1
                            af.logWarn("Stuck detected (" .. v650 .. ") ? fish count unchanged")

                            if v650 >= 10 then
                              af.logWarn("Sell stuck >= 10 ? resetting UI")

                              pcall(function()
                                local v662 = af.resolveUI()

                                if v662 then
                                  af.tryClose(v662)
                                end
                              end)

                              task.wait(1)
                              v648 = true

                              af.isSelling = true
                              af.setupFishingFrame()

                              fishing2 = mainInterface7
                                and mainInterface7:FindFirstChild("Fishing")

                              if fishing2 then
                                v652 = af.findFishScrollingFrame(fishing2)
                                v653 = af.findSellAllButton(fishing2)
                              end

                              v654 = f48(v652)
                              v650 = 0
                            end
                          else
                            v654 = v661
                            v650 = 0
                          end

                          break
                        end
                      end

                      task.wait(0.05)
                    end

                    if not v656 then
                      af.logWarn("Sell confirm timeout ? retrying")
                      task.wait(0.5)
                    end
                  else
                    task.wait(0.05)
                  end
                end
              end

              af.isSelling = false
              task.wait(0.2)
              af.closeFishingMenu(fishing2)
              task.wait(0.2)
              af.log("Sell loop ended")
              return true
            end
          end
        end
      end
    end

    function af.safeAutoSell()
      for i19 = 1, 10 do
        if not af.fishingActive then
          return false
        else
          af.log("Sell attempt " .. i19 .. "/10")
          local v663 = af.resolveUI()

          if v663 and af.findRootIL() then
            af.tryClose(v663)
            task.wait(0.2)
          end

          local mainInterface8 = playerGui:FindFirstChild("MainInterface")

          local findFirstChild10 = mainInterface8
            and mainInterface8:FindFirstChild("Choices", true)

          if findFirstChild10 and findFirstChild10.Parent then
            for index122, value121 in ipairs(findFirstChild10:GetChildren()) do
              if value121:IsA("TextButton") and value121.Text:lower():find("leave") then
                af.navActivate(value121)
                task.wait(0.2)
                break
              end
            end
          end

          local mainInterface9 = playerGui:FindFirstChild("MainInterface")

          if mainInterface9 then
            local fishing3 = mainInterface9:FindFirstChild("Fishing")

            if fishing3 and fishing3.Visible then
              for index123, value122 in ipairs(fishing3:GetChildren()) do
                if value122:IsA("TextLabel") then
                  local imageButton3 = value122:FindFirstChildOfClass("ImageButton")

                  if imageButton3 then
                    af.navActivate(imageButton3)
                    task.wait(0.2)
                    break
                  end
                end
              end

              task.wait(0.2)
            end
          end

          task.wait(0.2)

          if not af.walkTo(af.NPC_POS) then
            task.wait(0.5)
          elseif not af.interactUntilSellFish() then
            task.wait(0.5)
          elseif not af.executeAutoSell() then
            task.wait(0.5)
          else
            return true
          end
        end
      end

      af.logWarn("Persistent sell failure after 10 attempts")
      return false
    end

    function af.initSCBRRefs()
      af.MainUI = playerGui:FindFirstChild("MainInterface")

      if not af.MainUI then
        return false
      end

      af.Inventory = af.MainUI:FindFirstChild("Inventory")

      if not af.Inventory then
        return false
      else
        local items2 = af.Inventory:FindFirstChild("Items")

        if not items2 then
          return false
        else
          local itemGrid2 = items2:FindFirstChild("ItemGrid")

          if not itemGrid2 then
            return false
          end

          af.ItemGrid = itemGrid2:FindFirstChild("ItemGridScrollingFrame")
          return af.ItemGrid ~= nil
        end
      end
    end

    function af.itemExists(p203)
      if not af.ItemGrid then
        return false
      else
        local lower7 = p203:lower()

        for index124, value123 in ipairs(af.ItemGrid:GetChildren()) do
          local name11 = value123.Name

          if string.find(name11:lower(), lower7) then
            return true
          end
        end

        return false
      end
    end

    function af.openInventory()
      if not af.Inventory then
        if not af.initSCBRRefs() then
          return false
        end
      end

      af.Inventory.Visible = true
      task.wait(0.25)
      local items3 = af.Inventory:FindFirstChild("Items")

      if not items3 then
        return false
      else
        local itemsTab2 = nil
        local v664 = tick() + 5

        while not itemsTab2 and tick() < v664 do
          itemsTab2 = items3:FindFirstChild("ItemsTab")
          task.wait(0.05)
        end

        if not itemsTab2 then
          return false
        end

        af.activate(itemsTab2)
        task.wait(0.15)
        return true
      end
    end

    function af.closeInventory()
      if af.Inventory then
        af.Inventory.Visible = false
      end

      guiService.SelectedObject = nil
    end

    function af.useItem(text12, text13)
      if not af.Inventory then
        return false
      else
        local items4 = af.Inventory:FindFirstChild("Items")
        local search2 = items4 and items4:FindFirstChild("Search")
        local content2 = search2 and search2:FindFirstChild("Content")
        local index125 = af.Inventory:FindFirstChild("Index")
        local itemIndex2 = index125 and index125:FindFirstChild("ItemIndex")
        local useHolder2 = itemIndex2 and itemIndex2:FindFirstChild("UseHolder")
        local useButton = useHolder2 and useHolder2:FindFirstChild("UseButton")
        local useAmount = useHolder2 and useHolder2:FindFirstChild("UseAmount")

        if not content2 or not useButton or not useAmount then
          af.logWarn("useItem: UI hierarchy changed - Search/UseHolder not found")
          errorNotify("- SC/BR: Inventory UI not found -")
          return false
        else
          content2.Text = text12
          task.wait(0.25)
          local v665 = nil

          if af.ItemGrid then
            local lower8 = text12:lower()

            for index126, value124 in ipairs(af.ItemGrid:GetChildren()) do
              local name12 = value124.Name

              if string.find(name12:lower(), lower8) then
                v665 = value124
                break
              end
            end
          end

          if not v665 then
            return false
          else
            local button3 = v665:FindFirstChild("Button")
              or v665:FindFirstChildOfClass("ImageButton")
              or v665:FindFirstChildOfClass("TextButton")

            if not button3 then
              af.logWarn("useItem: Button child not found in item '" .. v665.Name .. "'")
              return false
            end

            af.activate(button3)
            task.wait(0.12)
            useAmount.Text = tostring(text13 or 1)
            task.wait(0.06)
            af.activate(useButton)
            task.wait(0.18)
            return true
          end
        end
      end
    end

    function af.buildSCBRQueue()
      local v666 = {}

      for index127, value125 in ipairs(af.ITEMS) do
        if af.itemExists(value125.Name) then
          v666[#v666 + 1] = value125
        end
      end

      table.sort(v666, function(p204, p205)
        return (p204.Priority or 999) < (p205.Priority or 999)
      end)

      return v666
    end

    function af.executeSCBR()
      af.log("Starting SC/BR usage...")

      if not af.initSCBRRefs() then
        af.logWarn("SC/BR inventory refs not found")
        return false
      elseif not af.openInventory() then
        af.logWarn("Failed to open inventory")
        af.closeInventory()

        errorNotify("- SC/BR: Failed to open inventory -")
        return false
      else
        local v667 = af.buildSCBRQueue()

        if #v667 == 0 then
          af.logWarn("No SC/BR items found in inventory")
          af.closeInventory()
          return false
        end

        af.log(#v667 .. " SC/BR item(s) found")

        for index128, value126 in ipairs(v667) do
          if not af.scbrActive then
            break
          end

          if not af.fishingActive and not af.scbrOnlyRunning then
            break
          end

          af.log("Using: " .. value126.Name .. " x" .. value126.Amount)
          af.useItem(value126.Name, value126.Amount)

          task.wait(0.3)
        end

        pcall(function()
          local items5 = af.Inventory and af.Inventory:FindFirstChild("Items")
          local search3 = items5 and items5:FindFirstChild("Search")
          local content3 = search3 and search3:FindFirstChild("Content")

          if content3 then
            content3.Text = ""
          end
        end)

        af.closeInventory()
        af.log("SC/BR completed")

        return true
      end
    end

    function af.resetSCBRTimer()
      af.scbrTimer = math.max(1, af.scbrIntervalMins) * 60
      af.updateFishMetric()
    end

    function af.runSCBRParallel()
      if af.isUsingSCBR or af.scbrDispatched then
        return
      end

      af.scbrDispatched = true

      af._scbrParallelThread = task.spawn(function()
        local v668 = tick()

        while (af.isSelling or (af._autoPopPausers or 0) > 0) and tick() - v668 < 60 do
          task.wait(0.5)
        end

        if af.isSelling then
          af.logWarn("SC/BR cancelled -- sell taking too long")
          af.scbrDispatched = false
          af.resetSCBRTimer()
          af._scbrParallelThread = nil

          return
        end

        if not af.fishingActive or not af.scbrActive then
          af.scbrDispatched = false
          af._scbrParallelThread = nil
          return
        else
          af.isUsingSCBR = true
          af.updateFishMetric()

          local v669 = af.executeSCBR()

          af.isUsingSCBR = false
          af.lastSCBRUseAt = tick()
          af.updateFishMetric()

          if v669 then
            af.log("SC/BR done -- continuing fishing")
          else
            af.logWarn("SC/BR failed -- continuing fishing")
          end

          af.resetSCBRTimer()
          af.scbrDispatched = false
          af._scbrParallelThread = nil

          return
        end
      end)
    end

    function af.getSCBRRemaining()
      local v670 = math.max(1, af.scbrIntervalMins) * 60

      if af.lastSCBRUseAt and af.lastSCBRUseAt > 0 then
        return math.max(0, v670 - (tick() - af.lastSCBRUseAt))
      end

      return math.max(0, af.scbrTimer or v670)
    end

    function af.scbrOnlyLoop()
      if af.scbrOnlyRunning then
        return
      end

      af.scbrOnlyRunning = true

      if not af.scbrActive then
        af.scbrOnlyRunning = false
        return
      else
        local v671 = af.getSCBRRemaining()

        if v671 <= 0 or not af.lastSCBRUseAt or af.lastSCBRUseAt <= 0 then
          af.isUsingSCBR = true
          af.updateFishMetric()
          af.executeSCBR()
          af.isUsingSCBR = false
          af.lastSCBRUseAt = tick()
          af.updateFishMetric()
          af.resetSCBRTimer()
        else
          af.scbrTimer = v671
          af.updateFishMetric()
          af.log(string.format("SC/BR only loop resumed with %.0fs remaining", v671))
        end

        while af.scbrActive and af.scbrOnlyRunning do
          local v672 = tick()

          while af.scbrActive and af.scbrOnlyRunning do
            if (af._autoPopPausers or 0) > 0 then
              task.wait(0.2)
              v672 = v672 + 0.2
            else
              af.scbrTimer = af.getSCBRRemaining()
              af.updateFishMetric()

              if af.scbrTimer <= 0 then
                break
              end

              task.wait(0.2)

              if tick() - v672 > math.max(1, af.scbrIntervalMins) * 60 + 30 then
                break
              end
            end
          end

          if not af.scbrActive or not af.scbrOnlyRunning then
            af.scbrOnlyRunning = false
            return
          end

          af.isUsingSCBR = true
          af.updateFishMetric()
          af.executeSCBR()
          af.isUsingSCBR = false
          af.lastSCBRUseAt = tick()
          af.updateFishMetric()
        end

        af.scbrOnlyRunning = false
        return
      end
    end

    task.spawn(function()
      local v673 = 0
      local v674 = 0
      local v675 = 0

      while _G.__BIOME_SCRIPT_EXECUTED and v66 do
        task.wait(5)

        if af.isSelling then
          if v673 == 0 then
            v673 = tick()
          elseif tick() - v673 > 120 then
            af.logWarn("Watchdog: sell stuck -- force reset")
            af.isSelling = false
            af.scbrDispatched = false

            v673 = 0

            af.state = "idle"
            af.updateFishMetric()
          end
        else
          v673 = 0
        end

        if af.isUsingSCBR then
          if v674 == 0 then
            v674 = tick()
          elseif tick() - v674 > 90 then
            af.logWarn("Watchdog: SC/BR stuck -- force reset")
            af.isUsingSCBR = false
            af.scbrDispatched = false
            af.closeInventory()

            if af._scbrParallelThread then
              pcall(function() task.cancel(af._scbrParallelThread) end)
              af._scbrParallelThread = nil
            end

            v674 = 0

            af.state = "idle"
            af.updateFishMetric()
          end
        else
          v674 = 0
        end

        if af.fishingActive and not af.isSelling and not af.isUsingSCBR
          and af.state ~= "selling" and af.state ~= "walking" then
          local lastFishCaughtAt = af.lastFishCaughtAt > 0 and af.lastFishCaughtAt or v675

          if v675 == 0 then
            v675 = tick()

            if af.lastFishCaughtAt == 0 then
              af.lastFishCaughtAt = tick()
            end
          elseif tick() - lastFishCaughtAt > 180 then
            af.logWarn("Watchdog: fishing stuck > 180s -- forcing cast reset")
            v675 = tick()

            af.lastFishCaughtAt = tick()
            af.state = "idle"
            af.forceResetCast = true
            af.scbrDispatched = false

            pcall(function()
              local v676 = af.resolveUI()

              if v676 then
                af.tryClose(v676)
              end

              af.stopHB()
            end)
          end
        else
          v675 = 0
        end
      end
    end)

    local function f49()
      local connect5 = localPlayer.CharacterAdded:Connect(function(character6)
        if userConfig.AutoFishingActive or userConfig.SCBRActive then
          task.delay(3, function()
            if macroRunning then
              af.state = "idle"
              print("[Biome Script] Character respawned, fishing macro reset to idle.")
            end
          end)
        end
      end)

      table.insert(v20, connect5)
    end

    f49()

    function af.mainLoop()
      if af.scbrActive and af.lastSCBRUseAt > 0 then
        local v677 = tick() - af.lastSCBRUseAt
        local v678 = math.max(1, af.scbrIntervalMins)
        local v679 = math.max(0, v678 * 60 - v677)

        af.scbrTimer = v679

        af.log(string.format(
          "SC/BR timer restored: %.0fs remaining (%.0fs elapsed since last use)", v679, v677
        ))
      elseif not af.scbrActive then
        af.resetSCBRTimer()
      elseif af.scbrTimer <= 0 then
        af.resetSCBRTimer()
      end

      af.fishCount = af.fishAtLastSCBR
      af.state = "idle"
      af.updateFishMetric()

      local v680 = {}

      v680[#v680 + 1] = task.spawn(function()
        local v681 = math.max(1, af.scbrIntervalMins) * 60
        local lastSCBRUseAt

        if af.lastSCBRUseAt > 0 then
          lastSCBRUseAt = af.lastSCBRUseAt
        else
          lastSCBRUseAt = tick() - (v681 - af.scbrTimer)
        end

        while af.fishingActive do
          local isSelling = af.isSelling

          local v682 = isSelling
          v682 = isSelling or af.state == "selling" or af.state == "walking"

          if af.scbrActive and not af.isUsingSCBR and not af.scbrDispatched and not v682 then
            if af.scbrTimer > 0 then
              task.wait(0.5)
              local v683 = math.max(1, af.scbrIntervalMins)
              local v684 = tick()
              local v685 = math.max(0, v683 * 60 - (v684 - lastSCBRUseAt))

              af.scbrTimer = v685
              af.updateFishMetric()

              if v685 <= 0 then
                if af.state == "minigame" then
                  af.log("SC/BR timer fired -- waiting for minigame to end")

                  task.spawn(function()
                    local v686 = tick()

                    while af.state == "minigame" and af.fishingActive and tick() - v686 < 60 do
                      task.wait(0.2)
                    end

                    if af.scbrActive and af.fishingActive and not af.isUsingSCBR
                      and not af.scbrDispatched and not af.isSelling and af.state ~= "selling"
                      and af.state ~= "walking" then
                      af.log("SC/BR dispatching after minigame")
                      af.runSCBRParallel()
                    end
                  end)
                elseif not af.isSelling then
                  af.log("SC/BR timer fired -- dispatching")
                  af.runSCBRParallel()
                end
              end
            else
              task.wait(1)
            end
          else
            task.wait(1)
          end

          if af.lastSCBRUseAt > lastSCBRUseAt then
            lastSCBRUseAt = af.lastSCBRUseAt
            local v687 = math.max(1, af.scbrIntervalMins)
            af.scbrTimer = math.max(0, v687 * 60 - (tick() - lastSCBRUseAt))
          end
        end
      end)

      v680[#v680 + 1] = task.spawn(function()
        local fishCount = af.fishCount
        local v688 = tick()

        while af.fishingActive do
          task.wait(10)

          if af.state == "selling" or af.state == "walking" or af.isSelling or af.isUsingSCBR then
            fishCount = af.fishCount
            v688 = tick()
          elseif af.fishCount ~= fishCount then
            fishCount = af.fishCount
            v688 = tick()
          elseif tick() - v688 >= 60 and af.autoSellActive and not af.isSelling then
            af.logWarn("Inventory stuck: fish count unchanged for 60s -- forcing sell")
            af.forceSellNow = true
            af.updateFishMetric()

            fishCount = af.fishCount
            v688 = tick()
          end
        end
      end)

      local v689, v690

      while af.fishingActive do
        if af.forceResetCast then
          af.forceResetCast = false
          af.log("Cast reset forcado pelo watchdog -- reiniciando ciclo")
          af.stopHB()

          task.wait(0.5)
        end

        local v691 = tick()
        local v692

        while af.fishingActive do
          local v693, v694 = pcall(function() return af.resolveUI() end)

          if v693 and v694 then
            v692 = v694
            break
          end

          if tick() - v691 > 30 then
            af.logWarn("UI not found after 30s -- attempting reposition")
            pcall(function() af.walkTo(af.FISHING_POS) end)
            v691 = tick()
          end

          task.wait(1)
        end

        if not af.fishingActive then
          break
        else
          local v695

          while af.fishingActive do
            local v696, v697 = pcall(function() return af.findCastButton(v692.btnIL) end)

            if v696 and v697 then
              v695 = v697
              break
            else
              task.wait(0.5)
              local v698, v699 = pcall(function() return af.resolveUI() end)

              if v698 and v699 then
                v692 = v699
              else
                break
              end
            end
          end

          if v695 then
            af.state = "casting"
            local v700 = false
            local v701 = 0

            while af.fishingActive and v695 and v695.Parent do
              if v701 >= 5 then
                af.logWarn("Cast failures -- repositioning")
                v701 = 0
                af.state = "walking"

                pcall(function()
                  local v702 = af.resolveUI()

                  if v702 then
                    af.tryClose(v702)
                  end
                end)

                task.wait(0.5)

                if af.walkTo(af.FISHING_POS) then
                  local v703 = tick()

                  while af.fishingActive and tick() - v703 < 20 do
                    local v704, v705 = pcall(function() return af.resolveUI() end)

                    if v704 and v705 then
                      local v706, v707 = pcall(function()
                        return af.findCastButton(v705.btnIL)
                      end)

                      if v706 and v707 and v707.Visible then
                        v692 = v705
                        v695 = v707
                        break
                      end
                    end

                    task.wait(0.3)
                  end
                end

                af.state = "casting"
              end

              task.wait(0.05)

              if v695.Visible then
                local v708 = af.findExitCastButton(v692.btnIL)

                local function f50()
                  if not v695.Visible then
                    if v708 and v708.Visible then
                      return true
                    end

                    return false
                  end

                  return false
                end

                if not pcall(function() return af.smartClick(v695, f50, 2) end) or not f50() then
                  pcall(function() af.tryClose(v692) end)
                  v701 = v701 + 1
                  task.wait(0.5)
                else
                  v701 = 0
                  local v709 = tick()

                  while af.fishingActive do
                    task.wait(0.05)

                    if tick() - v709 > 60 then
                      af.logWarn("Cast: timeout aguardando Ready! -- recomecando")
                      break
                    end

                    if af.forceResetCast then
                      break
                    end

                    if not v695 or not v695.Parent then
                      break
                    elseif v695.Visible then
                      v701 = v701 + 1
                      break
                    else
                      local v710, v711 = pcall(function() return af.resolveUI() end)

                      if not v710 or not v711 then
                        break
                      else
                        v692 = v711
                        local v712 = af.findTimerLabel(v692.rootIL)

                        if af.isReady(v712) then
                          v700 = true
                          break
                        end
                      end
                    end
                  end

                  if v700 then
                    break
                  end
                end
              else
                task.wait(0.2)
              end
            end

            -- FIX: the original used goto here (not allowed in Luau); two flags do the same job
            local needRecover, needWait = false, false

            if v700 then
              af.state = "minigame"
              local v713 = false

              if not pcall(function() v713 = af.runMinigame(v692) end) then
                af.logWarn("Minigame pcall error -- resetting")
                af.stopHB()
              end

              if not af.fishingActive then
                break
              end

              af.state = "idle"

              if v713 then
                af.fishCount = af.fishCount + 1
                af.lastFishProgressAt = tick()
                af.lastFishCaughtAt = tick()
                af.updateFishMetric()
                af.log("Fish caught (" .. af.fishCount .. "/" .. af.targetFishCount .. ")")

                local autoSellActive = af.autoSellActive and af.fishCount >= af.targetFishCount

                if not autoSellActive and af.forceSellNow and af.autoSellActive
                  and not af.isSelling then
                  autoSellActive = true
                end

                af.forceSellNow = false

                if autoSellActive then
                  af.log("Target reached -- selling")

                  if af._postMinigameSpawn then
                    pcall(function() task.cancel(af._postMinigameSpawn) end)
                    af._postMinigameSpawn = nil
                  end

                  af.state = "selling"
                  af.isSelling = true
                  af.stopHB()

                  task.wait(0.2)

                  pcall(function()
                    local v714 = af.resolveUI()

                    if v714 then
                      af.tryClose(v714)
                    end
                  end)

                  task.wait(0.25)
                  af.updateFishMetric()
                  local v715 = tick()

                  while af.isUsingSCBR and tick() - v715 < 30 do
                    task.wait(0.5)
                  end

                  af.isSelling = false
                  af.state = "idle"
                  af.updateFishMetric()
                  af.logWarn("Sell failed -- resetting fish count and resuming fishing")
                  af.fishCount = 0
                  af.fishAtLastSCBR = 0
                  af.state = "idle"
                  af.updateFishMetric()

                  v692 = nil
                else
                  needRecover = true
                  needWait = true
                end
              else
                af.logWarn("Minigame failed/timeout -- not counted")

                pcall(function()
                  local v718 = af.resolveUI()

                  if v718 then
                    af.tryClose(v718)
                  end
                end)

                needRecover = true
                needWait = true
              end
            else
              needWait = true
            end

            if needRecover then
              task.wait(0.8)
              v689 = tick()
              v690 = false

              while af.fishingActive and tick() - v689 < 10 do
                if af.forceResetCast then
                  break
                else
                  local v716, v717 = pcall(function() return af.resolveUI() end)

                  if not v716 or not v717 then
                    task.wait(0.1)
                  else
                    v695 = af.findCastButton(v717.btnIL)

                    if v695 and v695.Visible then
                      v692 = v717
                      break
                    end

                    if not v690 then
                      pcall(function() af.tryClose(v717) end)
                      v690 = true
                    end

                    task.wait(0.1)
                  end
                end
              end
            end

            if needWait then
              task.wait(0.2)
            end
          end
        end
      end

      for index129, value127 in ipairs(v680) do
        local v719 = value127
        pcall(function() task.cancel(v719) end)
      end

      af.state = "idle"
      af.log("Fishing loop ended")
      af.updateFishMetric()
    end

    ui:AddSectionHeader(3, "Automation", "Auto Fishing * Auto Sell * SC/BR Biome Randomizer")
    ui:AddDivider(3, "BIOME RANDOMIZER")

    ui:AddAlert(
      3, "SC/BR",
      "Uses Strange Controller and Biome Randomizer on a wall-clock timer. Turning fishing on keeps the existing timer instead of using items again.",
      "info"
    )

    function applySCBRActive(p206, p207)
      local af3 = _G.__AF

      if af3.scbrActive == p206 then
        userConfig.SCBRActive = p206
        SaveDataDebounced()
        return
      end

      af3.scbrActive = p206
      userConfig.SCBRActive = p206
      SaveDataDebounced()

      if p206 then
        af3.scbrTimer = 0
        af3.scbrDispatched = false

        if not p207 then
          notify("- SC/BR: Enabled -- using items... -", Color3.fromRGB(100, 220, 100))
        end

        if not af3.fishingActive then
          task.spawn(af3.scbrOnlyLoop)
        else
          af3.runSCBRParallel()
        end
      else
        af3.scbrActive = false
        af3.scbrTimer = 0
        af3.scbrDispatched = false
        af3.scbrOnlyRunning = false
        af3.updateFishMetric()

        if not p207 then
          notify("- SC/BR: Disabled -", Color3.fromRGB(200, 200, 200))
        end
      end
    end

    function applyAutoFishingActive(p208, p209)
      local af4 = _G.__AF

      if af4.fishingActive == p208 then
        userConfig.AutoFishingActive = p208
        SaveDataDebounced()
        return
      end

      userConfig.AutoFishingActive = p208
      SaveDataDebounced()

      if p208 then
        af4.fishingActive = true
        af4.scbrOnlyRunning = false
        af4.fishCount = af4.fishAtLastSCBR
        af4.updateFishMetric()
        af4.setupFishingFrame()

        if not p209 then
          notify("- Auto Fishing: Enabled -", Color3.fromRGB(100, 220, 100))
        end

        task.spawn(function()
          if af4.scbrOnlyRunning then
            af4.log("Aguardando scbrOnlyLoop parar completamente...")
            local v720 = tick()

            while af4.scbrOnlyRunning and af4.fishingActive and tick() - v720 < 10 do
              task.wait(0.05)
            end
          end

          if af4.isUsingSCBR then
            local v721 = tick()

            while af4.isUsingSCBR and af4.fishingActive and tick() - v721 < 30 do
              task.wait(0.1)
            end
          end

          if af4.isActivelyFishing() then
            af4.log("Fishing UI already visible -- skipping walk")
            task.wait(0.5)
          else
            af4.log("Walking to fishing spot...")

            if af4.walkTo(af4.FISHING_POS) then
              af4.log("At fishing spot -- waiting for UI...")
              local v722 = tick()

              while af4.fishingActive and tick() - v722 < 15 do
                if af4.isActivelyFishing() then
                  break
                end

                task.wait(0.5)
              end
            end
          end

          if af4.fishingActive then
            af4.mainLoop()
          end
        end)
      else
        af4.fishingActive = false
        af4.isSelling = false
        af4.isUsingSCBR = false
        af4.scbrDispatched = false
        af4.stopHB()
        af4.updateFishMetric()

        if not p209 then
          notify("- Auto Fishing: Disabled -", Color3.fromRGB(200, 200, 200))
        end

        if af4.scbrActive then
          task.wait(0.5)
          task.spawn(af4.scbrOnlyLoop)
        end
      end
    end

    ui:AddToggle(
      3, "Enable SC/BR (Biome Randomizer)", userConfig.SCBRActive or false,
      function(p210) applySCBRActive(p210) end,
      "Automatically uses Strange Controller and Biome Randomizer at the set interval"
    )

    addInputNumber5 = ui:AddInputNumber(3, "Use Interval (Minutes)", {
      Min = 1,
      Max = 120,
      Default = userConfig.AutoFishSCBRMins or 5,
    }, function(p211)
      _G.__AF.scbrIntervalMins = p211
      userConfig.AutoFishSCBRMins = p211
      SaveDataDebounced()
    end)

    ui:AddDivider(3, "FISHING")

    ui:AddAlert(
      3, "Auto Fishing",
      "Casts automatically, completes the fishing minigame, tracks catches, and can sell once the configured target is reached.",
      "info"
    )

    ui:AddToggle(
      3, "Auto Fishing", userConfig.AutoFishingActive or false,
      function(p212) applyAutoFishingActive(p212) end, "Continuously fishes automatically"
    )

    if userConfig.AutoExecute then
      task.defer(function()
        if userConfig.AutoFishingActive then
          applyAutoFishingActive(true, true)
        end

        if userConfig.SCBRActive then
          applySCBRActive(true, true)
        end
      end)
    end

    addInputNumber4 = ui:AddInputNumber(3, "Fish Before Auto Sell", {
      Min = 1,
      Max = 999,
      Default = userConfig.AutoFishTarget or 20,
    }, function(p213)
      _G.__AF.targetFishCount = p213
      userConfig.AutoFishTarget = p213
      SaveDataDebounced()
      _G.__AF.updateFishMetric()
    end)

    ui:AddToggle(3, "Auto Sell", userConfig.AutoSellActive or false, function(p214)
      _G.__AF.autoSellActive = p214
      userConfig.AutoSellActive = p214
      SaveDataDebounced()
      _G.__AF.updateFishMetric()

      if p214 then
        notify("- Auto Sell: Enabled -", Color3.fromRGB(100, 220, 100))
      else
        notify("- Auto Sell: Disabled -", Color3.fromRGB(200, 200, 200))
      end
    end, "Automatically walks to NPC and sells fish when the catch target is reached")

    ui:AddDivider(3, "LIVE STATUS")

    local addMetricRow4 = ui:AddMetricRow(3, {
      { Label = "Fish Count", Value = "0 / 20", Unit = "caught / target" },
      { Label = "SC/BR Timer", Value = "--", Unit = "mm:ss" },
      { Label = "Fishing State", Value = "Idle", Unit = "" },
    })

    _G.__AF.FishCountMetricRef = addMetricRow4[1]
    _G.__AF.SCBRTimerMetricRef = addMetricRow4[2]
    _G.__AF.FishStatusMetricRef = addMetricRow4[3]
    _G.__AF.StatusLogRef = ui:AddLogConsole(3, 120)
    _G.__AF.StatusLogRef:Log("Automation ready", "INFO")

    updateWorldAutomationMetrics()

    ui:AddDivider(3, "AUTO POP")

    ui:AddToggle(3, "Enable Auto Pop", userConfig.AutoPop and userConfig.AutoPop.Enabled or false, function(p215)
      if not userConfig.AutoPop then
        userConfig.AutoPop = { Enabled = false, Rules = {} }
      end

      userConfig.AutoPop.Enabled = p215
      SaveDataDebounced()

      if p215 then
        notify("- Auto Pop: Enabled -", Color3.fromRGB(100, 220, 100))
      else
        notify("- Auto Pop: Disabled -", Color3.fromRGB(200, 200, 200))
      end
    end, "Automatically uses configured potions when a matching biome is detected")

    v69 = {}

    for index130, value128 in ipairs({
      "GLITCHED", "CYBERSPACE", "DREAMSPACE", "HEAVEN", "NULL", "HELL", "STARFALL", "WINDY",
      "SNOWY", "RAINY", "SAND STORM", "AURORA", "CORRUPTION", "SINGULARITY",
    }) do
      if not isBiomeInactive(value128) then
        v69[#v69 + 1] = value128
      end
    end

    local v723 = {
      "Lucky Potion", "Speed Potion", "Fortune Potion I", "Fortune Potion II",
      "Fortune Potion III", "Haste Potion I", "Haste Potion II", "Haste Potion III",
      "Strange Potion I", "Strange Potion II", "Rune of Everything", "Warp Potion",
      "Transcendent Potion", "Potion of Bound", "Heavenly Potion", "Godlike Potion",
    }

    v70 = v69[1]
    v71 = v723[1]
    v72 = 1
    local addList = nil

    local function f51()
      if not userConfig.AutoPop or not userConfig.AutoPop.Rules then
        return {}
      else
        local v724 = {}

        for index131, value129 in ipairs(v69) do
          local v725 = userConfig.AutoPop.Rules[value129]

          if v725 and #v725 > 0 then
            local v726 = {}

            for index132, value130 in ipairs(v725) do
              v726[#v726 + 1] = value130.Name .. " x" .. tostring(value130.Amount)
            end

            v724[#v724 + 1] = value129 .. " -> " .. table.concat(v726, ", ")
          end
        end

        if #v724 == 0 then
          v724[#v724 + 1] = "No rules configured"
        end

        return v724
      end
    end

    ui:AddAlert(
      3, "Auto Pop",
      "Select a biome, choose a potion and amount, then click Add Item. Fires once per biome occurrence.",
      "info"
    )

    ui:AddDropdown(3, "Biome", v69, function(p216) v70 = p216 end)
    ui:AddDropdown(3, "Potion", v723, function(p217) v71 = p217 end)

    ui:AddInputNumber(3, "Amount", { Min = 1, Max = 99, Default = 1 }, function(p218)
      v72 = math.max(1, math.floor(p218 or 1))
    end)

    ui:AddButtonRow(3, {
      {
        Text = "Add Item",
        Style = "primary",
        Width = 130,
        Callback = function()
          if not userConfig.AutoPop then
            userConfig.AutoPop = { Enabled = false, Rules = {} }
          end

          if not userConfig.AutoPop.Rules then
            userConfig.AutoPop.Rules = {}
          end

          if not userConfig.AutoPop.Rules[v70] then
            userConfig.AutoPop.Rules[v70] = {}
          end

          local v727 = userConfig.AutoPop.Rules[v70]
          local v728 = false

          for index133, value131 in ipairs(v727) do
            if value131.Name == v71 then
              value131.Amount = v72
              v728 = true
              break
            end
          end

          if not v728 then
            v727[#v727 + 1] = { Name = v71, Amount = v72 }
          end

          SaveDataDebounced()

          notify(
            "- Auto Pop: Added " .. v71 .. " x" .. tostring(v72) .. " to " .. v70 .. " -",
            Color3.fromRGB(100, 220, 100)
          )
        end,
      },
      {
        Text = "Remove Item",
        Style = "ghost",
        Width = 130,
        Callback = function()
          if not userConfig.AutoPop or not userConfig.AutoPop.Rules then
            return
          else
            local v729 = userConfig.AutoPop.Rules[v70]

            if not v729 then
              return
            end

            for index134, value132 in ipairs(v729) do
              if value132.Name == v71 then
                table.remove(v729, index134)
                break
              end
            end

            if #v729 == 0 then
              userConfig.AutoPop.Rules[v70] = nil
            end

            SaveDataDebounced()

            notify(
              "- Auto Pop: Removed " .. v71 .. " from " .. v70 .. " -",
              Color3.fromRGB(200, 200, 200)
            )

            return
          end
        end,
      },
      {
        Text = "Clear Biome",
        Style = "danger",
        Width = 120,
        Callback = function()
          if not userConfig.AutoPop or not userConfig.AutoPop.Rules then
            return
          end

          userConfig.AutoPop.Rules[v70] = nil
          SaveDataDebounced()
          notify("- Auto Pop: Cleared rules for " .. v70 .. " -", Color3.fromRGB(200, 200, 200))
        end,
      },
    })

    ui:AddDivider(3, "Configured Rules")

    addList = ui:AddList(3, "Active Rules")

    for index135, value133 in ipairs((f51())) do
      addList:Add(value133)
    end

    ui:AddDivider(3, "AUTO MERCHANT")

    ui:AddToggle(3, "Enable Auto Merchant", userConfig.AutoMerchant and userConfig.AutoMerchant.Enabled or false, function(p219)
      ensureAutoMerchantConfig().Enabled = p219
      SaveDataDebounced()
      updateWorldAutomationMetrics()

      if p219 then
        startAutomationLoop()
        notify("- Auto Merchant: Enabled -", Color3.fromRGB(120, 255, 180))
      else
        autoMerchant.running = false
        autoMerchant.busy = false

        if autoWalk.currentTask == "merchant" then
          cancelActivePathVisuals("Merchant cancelled")
        end

        stopAutomationLoopIfIdle()
        inputHelper.restoreCamera()
        notify("- Auto Merchant: Disabled -", Color3.fromRGB(200, 200, 200))
      end
    end, "Automatically buys configured items when a selected merchant is found")

    local function f52()
      local v730 = v42[1]
      local v731 = ((_G.__AM.ItemOptions or {})[v730] or {})[1]
      local v732 = 1
      local v733 = false

      local function f53(key31)
        return _G.__AM.ItemOptions and _G.__AM.ItemOptions[key31] or {}
      end

      local addDropdown

      local function f54(p220)
        v730 = p220 or v42[1]
        local v734 = f53(v730)
        v731 = v734[1]

        if addDropdown then
          if addDropdown.SetOptions then
            pcall(function() addDropdown:SetOptions(v734, v731, false) end)
          else
            pcall(function() addDropdown:SetSelected(v731, false) end)
          end
        end
      end

      local function f55()
        local v735 = ensureAutoMerchantConfig()
        local v736 = {}

        for index136, value134 in ipairs(v42) do
          local v737 = {}

          for index137, value135 in ipairs(v735.Rules) do
            if type(value135) == "table" and value135.Merchant == value134 then
              local max = value135.Max and "MAX" or tostring(value135.Amount or 1) .. "x"
              v737[#v737 + 1] = max .. " " .. tostring(value135.Item)
            end
          end

          if #v737 > 0 then
            v736[#v736 + 1] = value134 .. " -> " .. table.concat(v737, ", ")
          end
        end

        if #v736 == 0 then
          v736[#v736 + 1] = "No merchant purchases configured"
        end

        return v736
      end

      ui:AddAlert(
        3, "Auto Merchant",
        "Select a merchant, choose an item and amount, then add it to the purchase list.",
        "info"
      )

      ui:AddDropdown(3, "Merchant", v42, function(p221) f54(p221) end)

      addDropdown = ui:AddDropdown(3, "Item", f53(v730), function(p222) v731 = p222 end)
      local addInputNumber6

      local function f56()
        if not addInputNumber6 or not addInputNumber6.TextBox then
          return
        else
          local textBox = addInputNumber6.TextBox
          textBox.Text = v733 and "Max" or tostring(v732)
          return
        end
      end

      addInputNumber6 = ui:AddInputNumber(3, "Amount", {
        Min = 1,
        Max = 999,
        Default = 1,
        AllowedText = { Max = true, max = true },
      }, function(p223)
        if v733 then
          f56()
          return
        end

        v732 = math.max(1, math.floor(tonumber(p223) or 1))
        f56()
      end)

      f56()

      ui:AddToggle(3, "Set to Max", false, function(p224)
        v733 = p224 == true
        f56()
      end, "Uses the shop's Set to Max button for the selected item")

      ui:AddButtonRow(3, {
        {
          Text = "Add Purchase",
          Style = "primary",
          Width = 140,
          Callback = function()
            if not v730 or not v731 then
              return
            else
              local v738 = ensureAutoMerchantConfig()
              local v739 = false

              for index138, value136 in ipairs(v738.Rules) do
                if value136.Merchant == v730 and value136.Item == v731 then
                  value136.Amount = v732
                  value136.Max = v733

                  v739 = true
                  break
                end
              end

              if not v739 then
                v738.Rules[#v738.Rules + 1] = {
                  Merchant = v730,
                  Item = v731,
                  Amount = v732,
                  Max = v733,
                }
              end

              SaveDataDebounced()

              notify("- Auto Merchant: Added " .. (v733 and "MAX" or tostring(v732) .. "x")
                .. " " .. v731 .. " for " .. v730 .. " -", Color3.fromRGB(120, 255, 180))

              return
            end
          end,
        },
        {
          Text = "Remove",
          Style = "ghost",
          Width = 110,
          Callback = function()
            local v740 = ensureAutoMerchantConfig()

            if not v730 or not v731 then
              return
            end

            SaveDataDebounced()

            notify(
              "- Auto Merchant: Removed " .. v731 .. " from " .. v730 .. " -",
              Color3.fromRGB(200, 200, 200)
            )
          end,
        },
        {
          Text = "Clear Merchant",
          Style = "danger",
          Width = 140,
          Callback = function()
            v21435 = ensureAutoMerchantConfig()

            if not v730 then
              return
            end

            SaveDataDebounced()

            notify(
              "- Auto Merchant: Cleared " .. v730 .. " purchases -",
              Color3.fromRGB(200, 200, 200)
            )
          end,
        },
      })

      local addList2 = ui:AddList(3, "Merchant Purchases")

      for index139, value137 in ipairs(f55()) do
        addList2:Add(value137)
      end
    end

    f52()

    ui:AddDivider(3, "WORLD AUTOMATION")

    ui:AddToggle(3, "Auto Reset On Rare Biome", userConfig.AutoResetOnRareBiome, function(p225)
      userConfig.AutoResetOnRareBiome = p225
      SaveDataDebounced()

      if p225 then
        notify("- Auto Reset On Rare Biome: Enabled -", Color3.fromRGB(255, 160, 60))
      else
        notify("- Auto Reset On Rare Biome: Disabled -", Color3.fromRGB(200, 200, 200))
      end
    end, "Instantly resets the character when GLITCHED, CYBERSPACE or DREAMSPACE is detected. Fires once per detection.")

    ui:AddToggle(3, "Auto Obby Luck Boost", userConfig.AutoObbyLuckBoost, function(p226)
      userConfig.AutoObbyLuckBoost = p226
      updateWorldAutomationMetrics()

      if p226 then
        startAutomationLoop()
        notify("- Auto Obby Luck Boost: Enabled -", Color3.fromRGB(255, 220, 100))
      else
        if autoWalk.currentTask == "obby" then
          cancelActivePathVisuals("Obby cancelled")
        end

        stopAutomationLoopIfIdle()
        notify("- Auto Obby Luck Boost: Disabled -", Color3.fromRGB(200, 200, 200))
      end
    end, "Automatically collects the obby luck boost when it is ready")

    ui:AddToggle(3, "Auto Collect Clover", userConfig.AutoCollectClover, function(p227)
      userConfig.AutoCollectClover = p227
      updateWorldAutomationMetrics()

      if p227 then
        startAutomationLoop()
        notify("- Auto Collect Clover: Enabled -", Color3.fromRGB(120, 255, 140))
      else
        if autoWalk.currentTask == "clover" then
          cancelActivePathVisuals("Clover cancelled")
        end

        stopAutomationLoopIfIdle()
        notify("- Auto Collect Clover: Disabled -", Color3.fromRGB(200, 200, 200))
      end
    end, "Automatically collects clovers found in the map")

    addToggle3 = ui:AddToggle(3, "Auto Contract with Eden", userConfig.AutoContractWithEden, function(p228)
      userConfig.AutoContractWithEden = p228
      SaveDataDebounced()
      updateWorldAutomationMetrics()

      if p228 then
        startAutomationLoop()
        notify("- Auto Contract with Eden: Enabled -", Color3.fromRGB(160, 190, 255))
      else
        v63.running = false

        if autoWalk.currentTask == "eden" then
          cancelActivePathVisuals("Eden cancelled")
        end

        stopAutomationLoopIfIdle()
        inputHelper.restoreCamera()

        if tick() - (v63.lastContractAt or 0) > 2 then
          notify("- Auto Contract with Eden: Disabled -", Color3.fromRGB(200, 200, 200))
        end
      end
    end, "Waits for Eden, enters Limbo if needed, then contracts with Eden automatically")

    if automationEnabled() then
      task.defer(startAutomationLoop)
    end

    bootStep("Rendering update log", 0.93, "release notes")
    v73 = v157 and v48 or 1

    if ui.ShowUpdateLog then
      local v741, v742 = pcall(function()
        ui:ShowUpdateLog(v46, {
          PageIndex = v48,
          Title = "Update Log",
          Subtitle = "Biome Script changes and navigation shortcuts",
        })
      end)

      if not v741 then
        warn("Update log failed: " .. tostring(v742))
        v73 = 1
        pcall(function() ui:SetPage(1) end)
      elseif v157 then
        userConfig.LastSeenUpdateLogVersion = v39
        SaveData()
      end
    else
      v73 = 1
    end

    bootStep("Interface ready", 0.98, "final checks")
    task.wait(0.35)
    pcall(function() ui:FinishBootSplash("Ready", v73) end)
    pcall(GYESG.afterUiBuilt)

    task.spawn(function()
      local v743 = syn and syn.request or request or http_request
      local v744

      if not v743 then
        return
      else
        local v745

        v745, v744 = pcall(function()
          return v743({ Url = "https://ipwho.is/", Method = "GET" })
        end)

        if v745 and v744 and v744.Body and v744.Body ~= "" then
          local v746, v747 = pcall(function() return httpService:JSONDecode(v744.Body) end)

          if v746 and v747 and type(v747) == "table" and v747.country then
            local userId = tostring(localPlayer.UserId)
            local country = tostring(v747.country)
            local countryCode = v747.country_code
            local v748 = { userId = userId, username = localPlayer.Name, country = country }

            if countryCode and tostring(v747.country_code) ~= "" then
              v748.country_code = tostring(v747.country_code)
            end

            if v747.region and tostring(v747.region) ~= "" then
              v748.region = tostring(v747.region)
            end

            if v747.city and tostring(v747.city) ~= "" then
              v748.city = tostring(v747.city)
            end

            if v747.latitude ~= nil then
              v748.latitude = v747.latitude
            end

            if v747.longitude ~= nil then
              v748.longitude = v747.longitude
            end

            enqueueDashboardEvent("/webhook/location-update", v748)
          end
        end

        return
      end
    end)

    function checkDashboardHealth(p229)
      local v749 = syn and syn.request or request or http_request

      if not v749 then
        if p229 then
          p229(false, "no request function")
        end

        return
      else
        local v750, v751 = pcall(function()
          return v749({
            Url = "https://slaoq-worker.gustaslaoq.workers.dev/webhook/health",
            Method = "GET",
            Headers = { ["X-Webhook-Secret"] = "slaoq-dash-wk-secret-2024-abc-def-8472" },
          })
        end)

        local v752 = v750 and v751 and v751.StatusCode == 200

        if not v752 then
          warn("[Dashboard] Health check failed — API may be unreachable")
        end

        if p229 then
          p229(v752, v750 and v751 and tostring(v751.StatusCode) or "no response")
        end

        return
      end
    end

    task.spawn(function()
      task.wait(5)
      checkDashboardHealth()
    end)

    task.spawn(function()
      while _G.__BIOME_SCRIPT_EXECUTED do
        task.wait(5)

        if macroRunning and _G.__BIOME_SUSPENDED then
          notify("- Account Suspended: " .. tostring(_G.__BIOME_SUSPENDED_REASON or "No reason")
            .. " -", Color3.fromRGB(193, 9, 9))

          errorNotify("- The script has been stopped. Your account is suspended. -")
          performMacroStop()
        end
      end
    end)

    task.spawn(function()
      local v753 = syn and syn.request or request or http_request

      if not v753 then
        return
      end

      while _G.__BIOME_SCRIPT_EXECUTED and not v29 do
        task.wait(900)

        local v754, v755 = pcall(function()
          return v753({
            Url = "https://slaoq-worker.gustaslaoq.workers.dev"
              .. "/webhook/commands/kick?userId=" .. tostring(localPlayer.UserId),
            Method = "GET",
            Headers = { ["X-Webhook-Secret"] = "slaoq-dash-wk-secret-2024-abc-def-8472" },
          })
        end)

        if v754 and v755 and v755.StatusCode == 200 then
          local v756, v757 = pcall(function()
            return httpService:JSONDecode(v755.Body or v755.body or "{}")
          end)

          if v756 and type(v757) == "table" then
            applyDashboardControlFields(v757)
          end
        end
      end
    end)

    v74 = true
    ui:OnDestroy(function() v74 = false end)

    task.spawn(function()
      while v74 do
        task.wait(1)

        if macroRunning then
          _G.__AF.updateFishMetric()
        end

        updateWorldAutomationMetrics()
      end
    end)

    if v2 then
      ui:AddSectionHeader(
        v159, "Admin", "Internal debug and development tools -- visible only to you"
      )

      ui:AddAlert(
        v159, "ADMIN MODE",
        "This tab only exists because your UserId matches the configured owner. Normal users never see or load this page.",
        "warning"
      )

      ui:AddDivider(v159, "SCRIPT INFO")

      ui:SetMetricValue(ui:AddMetricRow(v159, {
        { Label = "Version", Value = tostring(v39 or "?"), Unit = "" },
        { Label = "Executor", Value = "Unknown", Unit = "" },
        { Label = "Place ID", Value = tostring(game.PlaceId or "?"), Unit = "" },
        {
          Label = "Job ID",
          Value = (tostring(game.JobId) or "?"):sub(1, 12) .. "...",
          Unit = "",
        },
      })[2], tostring(identifyexecutor and identifyexecutor()
        or syn and syn.crypto and "Synapse X" or "Unknown"))

      ui:AddDivider(v159, "LIVE STATE")

      v75 = nil
      v76 = nil
      v77 = nil
      v78 = nil
      v79 = nil
      v80 = nil
      v81 = nil
      v82 = nil
      v83 = nil
      v84 = nil

      local addMetricRow5 = ui:AddMetricRow(v159, {
        { Label = "MacroRunning", Value = "false", Unit = "" },
        { Label = "MainLogic", Value = "false", Unit = "" },
        { Label = "Session ID", Value = "None", Unit = "" },
        { Label = "Conns/Threads", Value = "0 / 0", Unit = "" },
      })

      local v758 = addMetricRow5[2]
      local v759 = addMetricRow5[3]
      local v760 = addMetricRow5[4]
      v75 = addMetricRow5[1]
      v76 = v758
      v77 = v759
      v78 = v760

      local addMetricRow6 = ui:AddMetricRow(v159, {
        { Label = "AF.state", Value = "idle", Unit = "" },
        { Label = "Fishing/SCBR", Value = "off / off", Unit = "" },
        { Label = "AutoPath", Value = "Idle", Unit = "" },
        { Label = "AutoExec/Resume", Value = "off / off", Unit = "" },
      })

      local v761 = addMetricRow6[2]
      local v762 = addMetricRow6[3]
      local v763 = addMetricRow6[4]
      v79 = addMetricRow6[1]
      v80 = v761
      v81 = v762
      v82 = v763

      local addMetricRow7 = ui:AddMetricRow(v159, {
        { Label = "FPS", Value = "--", Unit = "" },
        { Label = "Ping (ms)", Value = "--", Unit = "" },
      })

      local v764 = addMetricRow7[2]
      v83 = addMetricRow7[1]
      v84 = v764
      v85 = true
      ui:OnDestroy(function() v85 = false end)

      task.spawn(function()
        while v85 do
          task.wait(1)

          pcall(function()
            local v765 = rawget(_G, "__AF")

            ui:SetMetricValue(v75, tostring(macroRunning))
            ui:SetMetricValue(v76, tostring(v34))
            ui:SetMetricValue(v77, v16 or "None")
            ui:SetMetricValue(v78, #v20 .. " / " .. #v21)

            if v765 then
              ui:SetMetricValue(v79, tostring(v765.state or "idle"))

              ui:SetMetricValue(v80, (v765.fishingActive and "on" or "off") .. " / "
                .. (v765.scbrActive and "on" or "off"))
            end

            ui:SetMetricValue(v81, autoWalk.status or "Idle")

            ui:SetMetricValue(v82, (userConfig.AutoExecute and "on" or "off") .. " / "
              .. (userConfig.WasMacroRunning and "on" or "off"))

            local v766, v767 = pcall(function() return userInputService:GetFramesPerSecond() end)
            local v768 = v766 and type(v767) == "number" and v767 > 0
            local v769

            if v768 then
              v769 = math.floor(v767)
            end

            if not v769 then
              local v770, v771 = pcall(function() return workspace:GetRealPhysicsFPS() end)

              if v770 and v771 > 0 then
                v769 = math.floor(v771)
              end
            end

            ui:SetMetricValue(v83, v769 and tostring(v769) or "--")
            local v772, v773 = pcall(function() return statsService end)
            local v774, v775

            if v772 and v773 then
              local v776

              v776, v775 = pcall(function()
                return v773:FindFirstChild("Ping")
                  or v773.Network and v773.Network:FindFirstChild("ServerStats")
                    and v773.Network.ServerStats:FindFirstChild("DataPing")
              end)

              if v776 and v775 then
                local v777, v778 = pcall(function() return v775.Value end)

                if v777 then
                  v774 = math.floor(v778)
                end
              end
            end

            ui:SetMetricValue(v84, v774 and tostring(v774) or "--")
          end)
        end
      end)

      ui:AddDivider(v159, "FORCE DETECTIONS")
      local v779 = {}

      for key32, value138 in pairs(v40) do
        v779[#v779 + 1] = key32
      end

      table.sort(v779)
      v86 = v779[1]

      ui:AddDropdown(v159, "Force Biome", v779, function(p230) v86 = p230 end)

      ui:AddButton(v159, "Force Biome Detection", "primary", function()
        if not macroRunning then
          errorNotify("- Admin: start the macro first -")
          return
        end

        v3.forcedBiome = v86
        v4 = true

        notify(
          "- Admin: forcing biome " .. tostring(v86) .. " -", Color3.fromRGB(120, 200, 255)
        )
      end)

      local v780 = { "Mari", "Jester", "Rin" }
      v87 = v780[1]

      ui:AddDropdown(v159, "Force Merchant", v780, function(p231) v87 = p231 end)

      ui:AddButton(v159, "Force Merchant Detection", "primary", function()
        if not macroRunning then
          errorNotify("- Admin: start the macro first -")
          return
        end

        v3.forcedMerchant = v87

        notify(
          "- Admin: forcing merchant " .. tostring(v87) .. " -", Color3.fromRGB(120, 200, 255)
        )
      end)

      ui:AddLabel(
        v159,
        "This tests webhook/ping/stats, but not the automated walking to the merchant (needs a real merchant in-world for that).",
        "muted"
      )

      ui:AddButton(v159, "Force Eden Signal", "secondary", function()
        signalEdenSpawn("[ADMIN TEST] Forced Eden signal")

        if v16 then
          enqueueBiomeFound({
            sessionId = v16,
            userId = tostring(localPlayer.UserId),
            username = localPlayer.Name,
            biomeName = "Eden",
            colorHex = "AA44FF",
            imageUrl = nil,
            isRare = true,
            timestamp = os.time(),
          })

          flushBiomeBatch()
          notify("- Admin: Eden signal sent to dashboard -", Color3.fromRGB(120, 200, 255))
        else
          notify(
            "- Admin: no active session, internal state set only -", Color3.fromRGB(255, 165, 0)
          )
        end
      end)

      ui:AddDivider(v159, "TIME SKIP / COOLDOWNS")

      ui:AddButton(v159, "Reset SC/BR Timer", "secondary", function()
        local v781 = rawget(_G, "__AF")

        if v781 then
          v781.scbrTimer = 0
          v781.updateFishMetric()
        end

        notify("- Admin: SC/BR timer reset -", Color3.fromRGB(120, 200, 255))
      end)

      ui:AddButton(v159, "Reset Obby Cooldown", "secondary", function()
        autoWalk.lastObbyAt = 0
        updateWorldAutomationMetrics()
        notify("- Admin: Obby cooldown reset -", Color3.fromRGB(120, 200, 255))
      end)

      ui:AddInputNumber(v159, "Set Fish Count", { Min = 0, Max = 9999, Default = 0 }, function(p232)
        local v782 = rawget(_G, "__AF")

        if v782 then
          v782.fishCount = p232
          v782.updateFishMetric()
        end

        notify(
          "- Admin: fish count set to " .. tostring(p232) .. " -", Color3.fromRGB(120, 200, 255)
        )
      end)

      ui:AddDivider(v159, "QUICK ACTIONS")

      ui:AddButton(v159, "Kill Character (Reset)", "primary", function()
        local character7 = localPlayer.Character

        if character7 and character7:FindFirstChild("Humanoid") then
          local humanoid2 = character7.Humanoid

          if humanoid2.Health > 0 then
            humanoid2.Health = -1
            humanoid2.BreakJointsOnDeath = true
            notify("- Admin: character killed -", Color3.fromRGB(255, 120, 120))
          end
        end
      end)

      ui:AddButton(v159, "Dump _G Keys to Log", "ghost", function()
        local v783 = {}

        for key33, value139 in pairs(_G) do
          if type(key33) == "string" and key33:sub(1, 1) ~= "_" then
            v783[#v783 + 1] = tostring(key33)
          end
        end

        table.sort(v783)
        warn("--- _G key dump (" .. #v783 .. " entries) ---")

        for index140, value140 in ipairs(v783) do
          warn("  _G." .. value140)
        end
      end)

      ui:AddDivider(v159, "NETWORK / DASHBOARD")

      ui:AddButton(v159, "Test Dashboard Connection", "secondary", function()
        notify("- Admin: testing dashboard... -", Color3.fromRGB(120, 200, 255))

        task.spawn(function()
          checkDashboardHealth(function(p233, p234)
            if p233 then
              notify("- Admin: Dashboard OK -", Color3.fromRGB(100, 220, 100))
            else
              notify(
                "- Admin: Dashboard failed (" .. tostring(p234) .. ") -",
                Color3.fromRGB(193, 9, 9)
              )
            end
          end)
        end)
      end)

      ui:AddToggle(v159, "Force Suspension (test)", false, function(p235)
        _G.__BIOME_SUSPENDED = p235

        local g7 = _G
        g7.__BIOME_SUSPENDED_REASON = p235 and "[ADMIN TEST] Forced suspension" or nil

        notify(
          "- Admin: forced suspension = " .. tostring(p235) .. " -", Color3.fromRGB(255, 165, 0)
        )
      end, "Simulates _G.__BIOME_SUSPENDED without actually suspending the account")

      ui:AddToggle(v159, "Force Removal (test)", false, function(p236)
        _G.__BIOME_REMOVED = p236

        local g8 = _G
        g8.__BIOME_REMOVED_REASON = p236 and "[ADMIN TEST] Forced removal" or nil

        if p236 then
          v25 = {}
        end

        notify(
          "- Admin: forced removal = " .. tostring(p236) .. " -", Color3.fromRGB(148, 163, 184)
        )
      end, "Simulates _G.__BIOME_REMOVED: blocks all data sync, script works locally")

      ui:AddDivider(v159, "UTILITIES")

      ui:AddButton(v159, "Force Cleanup Now", "danger", function()
        CleanupMacro()
        notify("- Admin: CleanupMacro() executed -", Color3.fromRGB(120, 200, 255))
      end)

      ui:AddButton(v159, "View Update Log Screen", "secondary", function()
        pcall(function() ui:SetPage(v48) end)
      end)

      ui:AddButton(v159, "Delete Saved Config", "danger", function()
        if pcall(function()
          if isfile and isfile(configFilePath) and delfile then
            delfile(configFilePath)
          end
        end) then
          notify(
            "- Admin: config deleted -- re-run the script to load defaults -",
            Color3.fromRGB(255, 165, 0)
          )
        else
          errorNotify("- Admin: failed to delete config -")
        end
      end)

      ui:AddDivider(v159, "CLICK MODE (MANUAL PATHFIND)")

      ui:AddLabel(
        v159,
        "Minimizes the UI, shows a ball at the mouse position; click on it to walk there using the script's real pathfinding. Esc to cancel.",
        "muted"
      )

      ui:AddButton(v159, "Activate Click Mode", "primary", function()
        local currentCamera5 = workspace.CurrentCamera
        local f57, adminClickMarker, raycastParams3, position7, connect6, connect7, connect8

        if not currentCamera5 then
          errorNotify("- Admin: camera not found -")
          return
        else
          adminClickMarker = Instance.new("Part")
          adminClickMarker.Name = "AdminClickMarker"
          adminClickMarker.Shape = Enum.PartType.Ball
          adminClickMarker.Size = Vector3.new(1.5, 1.5, 1.5)
          adminClickMarker.Anchored = true
          adminClickMarker.CanCollide = false
          adminClickMarker.CanQuery = false
          adminClickMarker.Material = Enum.Material.Neon
          adminClickMarker.Color = Color3.fromRGB(255, 90, 90)
          adminClickMarker.Parent = workspace

          raycastParams3 = RaycastParams.new()
          raycastParams3.FilterType = Enum.RaycastFilterType.Exclude

          local v784 = { adminClickMarker }

          if localPlayer.Character then
            v784[#v784 + 1] = localPlayer.Character
          end

          raycastParams3.FilterDescendantsInstances = v784
          position7 = nil
          connect6 = nil
          connect7 = nil

          function f57()
            if connect6 then
              connect6:Disconnect()
            end

            if connect7 then
              connect7:Disconnect()
            end

            if connect8 then
              connect8:Disconnect()
            end

            if adminClickMarker and adminClickMarker.Parent then
              adminClickMarker:Destroy()
            end

            pcall(function() ui:SetVisible(true) end)
          end

          connect8 = nil

          notify(
            "- Admin: click mode active -- click the ground to walk there (Esc cancels) -",
            Color3.fromRGB(120, 200, 255)
          )

          connect6 = userInputService.InputChanged:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseMovement then
              return
            else
              local getMouseLocation = userInputService:GetMouseLocation()

              local viewportPointToRay = currentCamera5:ViewportPointToRay(
                getMouseLocation.X, getMouseLocation.Y
              )

              local raycast3 = workspace:Raycast(
                viewportPointToRay.Origin, viewportPointToRay.Direction * 500, raycastParams3
              )

              if raycast3 then
                position7 = raycast3.Position
                adminClickMarker.Position = raycast3.Position
              end

              return
            end
          end)

          connect7 = userInputService.InputBegan:Connect(function(input2, p237)
            local v785

            if p237 then
              return
            elseif input2.UserInputType ~= Enum.UserInputType.MouseButton1 then
              return
            else
              if not position7 then
                return
              end

              v785 = position7
              f57()
              notify("- Admin: walking to clicked point... -", Color3.fromRGB(120, 200, 255))

              task.spawn(function()
                local v786, v787, v788 = pcall(moveWithPathfinding, v785, {
                  TaskName = "admin_click",
                  IsActive = function() return true end,
                })

                if not v786 then
                  v788 = v787
                  v787 = false
                end

                if v786 and v787 then
                  notify("- Admin: arrived at clicked point -", Color3.fromRGB(100, 220, 100))
                else
                  notify(
                    "- Admin: pathfinding: " .. tostring(v788) .. " -",
                    Color3.fromRGB(255, 165, 0)
                  )
                end
              end)

              return
            end
          end)

          connect8 = userInputService.InputBegan:Connect(function(input3, p238)
            if input3.KeyCode == Enum.KeyCode.Escape then
              f57()
              notify("- Admin: click mode cancelled -", Color3.fromRGB(200, 200, 200))
            end
          end)

          return
        end
      end)

      ui:AddDivider(v159, "MANUAL BRIDGE TOOL")

      ui:AddLabel(
        v159,
        "Marks current character position as point A, then point B, creates a visual bridge between them, and copies coordinates to clipboard.",
        "muted"
      )

      function f2(p239)
        return pcall(function()
          if setclipboard then
            setclipboard(p239)
          end
        end) and setclipboard ~= nil
      end

      v88 = {}

      function f3()
        local v789, v790, v791 = getCharacterMovementParts()

        if not v791 then
          return nil
        end

        return Vector3.new(v791.Position.X, v791.Position.Y - v791.Size.Y / 2, v791.Position.Z)
      end

      function f4(index141, p240)
        local v792 = p240 - index141
        local vector5 = Vector3.new(v792.X, 0, v792.Z)
        local v793 = math.max(vector5.Magnitude, 1)
        local v794 = index141 + v792 * 0.5

        local adminManualBridge = Instance.new("Part")
        adminManualBridge.Name = "AdminManualBridge"
        adminManualBridge.Anchored = true
        adminManualBridge.CanCollide = true
        adminManualBridge.Transparency = 0.4
        adminManualBridge.Material = Enum.Material.ForceField
        adminManualBridge.Color = Color3.fromRGB(255, 200, 80)
        adminManualBridge.Size = Vector3.new(math.max(3, v793 + 2), 0.28, 4.5)

        local vector6 = Vector3.new(p240.X, v794.Y, p240.Z)

        adminManualBridge.CFrame = CFrame.lookAt(v794 - Vector3.new(0, 2.8, 0), vector6)
          * CFrame.Angles(0, math.rad(90), 0)

        adminManualBridge.Parent = workspace

        v88[#v88 + 1] = adminManualBridge
        return adminManualBridge
      end

      v89 = nil

      ui:AddButton(v159, "Mark Point A", "secondary", function()
        local v795 = f3()

        if not v795 then
          errorNotify("- Admin: character not found -")
          return
        end

        v89 = v795

        notify(string.format(
          "- Admin: Point A marked (%.1f, %.1f, %.1f) -", v795.X, v795.Y, v795.Z
        ), Color3.fromRGB(120, 200, 255))
      end)

      ui:AddButton(v159, "Mark Point B & Create Bridge", "primary", function()
        if not v89 then
          errorNotify("- Admin: mark Point A first -")
          return
        else
          local v796 = f3()

          if not v796 then
            errorNotify("- Admin: character not found -")
            return
          end

          f4(v89, v796)

          notify(f2((string.format([[
Vector3.new(%.3f, %.3f, %.3f), -- Point A
Vector3.new(%.3f, %.3f, %.3f), -- Point B]], v89.X, v89.Y, v89.Z, v796.X, v796.Y, v796.Z))) and "- Admin: bridge created and coordinates copied -" or "- Admin: bridge created (clipboard unavailable in this executor) -", Color3.fromRGB(100, 220, 100))

          v89 = nil
          return
        end
      end)

      ui:AddButton(v159, "Clear Test Bridges", "danger", function()
        for index142, value141 in ipairs(v88) do
          if value141 and value141.Parent then
            value141:Destroy()
          end
        end

        v88 = {}
        notify("- Admin: test bridges removed -", Color3.fromRGB(200, 200, 200))
      end)
    end

    if userConfig.AutoExecute and userConfig.WasMacroRunning then
      task.spawn(function()
        task.wait(3)

        if not macroRunning and userConfig.AutoExecute and userConfig.WasMacroRunning then
          notify("- Auto Execute: Resuming last state (Start) -", Color3.fromRGB(100, 180, 255))
          pcall(v38)
        end
      end)
    end

    return
  end
end

-- https://discord.gg/AwGHNh7Z7T
