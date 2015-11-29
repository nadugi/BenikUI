local E, L, V, P, G = unpack(ElvUI); --Inport: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local BUID = E:GetModule('BuiDashboard')

local select, collectgarbage = select, collectgarbage
local sort, wipe = table.sort, wipe
local format = string.format

local GetNumAddOns = GetNumAddOns
local GetAddOnInfo = GetAddOnInfo
local IsAddOnLoaded = IsAddOnLoaded
local UpdateAddOnMemoryUsage = UpdateAddOnMemoryUsage
local GetAddOnMemoryUsage = GetAddOnMemoryUsage

local kiloByteString = '|cfff6a01a %d|r'..' kb'
local megaByteString = '|cfff6a01a %.2f|r'..' mb'

local totalMemory = 0

local function formatMem( memory )
	local mem
	local mult = 10^1
	if( memory > 999 ) then
		mem = ( ( memory / 1024 ) * mult ) / mult
		return format( megaByteString, mem )
	else
		mem = ( memory * mult ) / mult
		return format( kiloByteString, mem )
	end
end

local function sortByMemory(a, b)
	if a and b then
		return a[3] > b[3]
	end
end

local memoryTable = {}

local function RebuildAddonList()
	local addOnCount = GetNumAddOns()
	if( addOnCount == #memoryTable ) then return end

	wipe( memoryTable )
	for i = 1, addOnCount do
		memoryTable[i] = { i, select( 2, GetAddOnInfo( i ) ), 0, IsAddOnLoaded( i ) }
	end
end

local function UpdateMemory()
	UpdateAddOnMemoryUsage()

	local addOnMemory = 0
	totalMemory = 0
	for i = 1, #memoryTable do
		addOnMemory = GetAddOnMemoryUsage(memoryTable[i][1])
		memoryTable[i][3] = addOnMemory
		totalMemory = totalMemory + addOnMemory
	end

	sort( memoryTable, sortByMemory )

	return totalMemory
end

local int = 10

local function Update( self, t )
	local boardName = Memory
	int = int - t

	if( int < 0 ) then
		RebuildAddonList(self)
		local total = UpdateMemory()
		boardName.Text:SetFormattedText("%s", (L['Memory: ']..formatMem(total)))
		boardName.Status:SetMinMaxValues( 0, 100000 )
		boardName.Status:SetValue( total )
		int = 10
	end
end

function BUID:CreateMemory()
	local boardName = Memory
	boardName:SetScript( 'OnMouseDown', function (self)
		collectgarbage( 'collect' )
	end )

	boardName:SetScript( 'OnEnter', function( self )
		if( not InCombatLockdown() ) then
			GameTooltip:SetOwner( boardName, 'ANCHOR_RIGHT', 5, 0 )
			GameTooltip:ClearLines()

			local totalMemory = UpdateMemory()
			local red, green
			for i = 1, #memoryTable do
				if( memoryTable[i][4] ) then
					red = memoryTable[i][3] / totalMemory
					green = 1 - red
					GameTooltip:AddDoubleLine( memoryTable[i][2], formatMem( memoryTable[i][3] ), 1, 1, 1, red, green + .5, 0 )
				end
			end
			GameTooltip:Show()
		end
	end )
	
	boardName:SetScript( 'OnLeave', function( self )
		GameTooltip:Hide()
	end )
	
	boardName.Status:SetScript( 'OnUpdate', Update )
end