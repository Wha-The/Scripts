-- Paid Exploit Library Example
local library = loadstring(game:HttpGet("https://pastebin.com/raw/eKwyeQa0", true))()

local BossesTab = library:CreateTab("Bosses", true)

local ListOfBosses = {
   "Ghastly Tree",
   "George the Gorilla",
   "Sludge",
   "Subject One",
   "King Krab",
   "Magmoraug",
}
local ChosenBoss = ""
local ChooseBoss = library:MakeDropdown(BossesTab,"Dropdown",{"Auto Detect", unpack(ListOfBosses)},"Ok",function(dropdown)
   ChosenBoss = dropdown.Text
end)
local toggle = library:MakeToggle(BossesTab,"Auto Kill Selected Boss",false,function(toggle)
   print(toggle.Text)
end)


local MegaBossesTab = library:CreateTab("Mega Bosses", true)
local ListOfMegaBosses = {
   "The Great Guardian",
   "Boss Bo",
}
local ChosenBoss = ""
local ChooseBoss = library:MakeDropdown(BossesTab,"Dropdown",{"Auto Detect", unpack(ListOfMegaBosses)},"Ok",function(dropdown)
   ChosenMegaBoss = dropdown.Text
end)
local toggle = library:MakeToggle(BossesTab,"Auto Kill Selected MegaBoss",false,function(toggle)
   print(toggle.Text)
end)
