-- ServerScriptService/Modules/RewardManager.lua (VERSIÓN MEJORADA)

local ServerScriptService = game:GetService("ServerScriptService")

-- Módulos necesarios
local GameStatsManager = require(ServerScriptService.Modules.Data.GameStatsManager)
local MessageManager = require(ServerScriptService.Modules.MessageManager) -- Para enviar mensajes al jugador
local PlayerManager = require(ServerScriptService.Modules.PlayerManager) -- Para saber quién está vivo

local RewardManager = {}

-- Tabla de recompensas más detallada
local RECOMPENSAS = {
	KillerWin = { Coins = 100, KillerWins = 1 },
	SurvivorWin = { Coins = 50, SurvivorWins = 1 },
	Participation = { Coins = 10 } -- Recompensa por solo jugar
}

function RewardManager.GiveRewards(killer, survivors, killerWon)
	-- === Reward the KILLER ===
	if killer:IsA("Player") then
		if killerWon then
			--print("Rewarding", killer.Name, "for WINNING as Killer.")
			GameStatsManager.AddStats(killer, RECOMPENSAS.KillerWin)
			-- Mensaje en inglés
			MessageManager.SendToPlayer(killer, "?? Victory! +" .. RECOMPENSAS.KillerWin.Coins .. " Coins.")
		else
			-- If the killer loses, they get a participation reward
			--print("Rewarding", killer.Name, "for PARTICIPATING as Killer.")
			GameStatsManager.AddStats(killer, RECOMPENSAS.Participation)
			-- Mensaje en inglés
			MessageManager.SendToPlayer(killer, "?? Participation: +" .. RECOMPENSAS.Participation.Coins .. " Coins.")
		end
	end

	-- === Reward the SURVIVORS ===
	for _, survivor in ipairs(survivors) do
		if survivor:IsA("Player") then
			if killerWon then
				-- The killer won, survivors only get a participation reward
				--print("Rewarding", survivor.Name, "for PARTICIPATING as Survivor.")
				GameStatsManager.AddStats(survivor, RECOMPENSAS.Participation)
				-- Mensaje en inglés
				MessageManager.SendToPlayer(survivor, "?? Participation: +" .. RECOMPENSAS.Participation.Coins .. " Coins.")
			else
				-- The survivors won.
				-- Only those who are STILL ALIVE at the end get the victory reward.
				if PlayerManager.IsEntityAlive(survivor) then
					--print("Rewarding", survivor.Name, "for SURVIVING and WINNING.")
					GameStatsManager.AddStats(survivor, RECOMPENSAS.SurvivorWin)
					-- Mensaje en inglés
					MessageManager.SendToPlayer(survivor, "?? You survived! +" .. RECOMPENSAS.SurvivorWin.Coins .. " Coins.")
				else
					-- Those who died but their team won get a participation reward
					--print("Rewarding", survivor.Name, "for PARTICIPATING (died but team won).")
					GameStatsManager.AddStats(survivor, RECOMPENSAS.Participation)
					-- Mensaje en inglés
					MessageManager.SendToPlayer(survivor, "?? Participation: +" .. RECOMPENSAS.Participation.Coins .. " Coins.")
				end
			end
		end
	end
end

return RewardManager