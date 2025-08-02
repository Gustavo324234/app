-- RUTA: ReplicatedStorage/Modules/Data/CharacterConfig.lua
-- VERSIÓN: CANÓNICA (Funciones originales intactas + IDs de animación correctos)

local CharacterConfig = {
	-- Clave principal para el rol de asesino
	Killer = {
		["Bacon Hair"] = {
			Price = 0,
			Icon = "rbxassetid://75252176542266",
			OwnedByDefault = true,
			Weapon = "Sarten",
			Abilities = { "GreaseTrail", "SizzlingSwing", "FryingFrenzy" },
			MaxHealth = 120,
			MaxStamina = 100,
			AttackStats = {
				Damage = 50,
				Range = 7,
				Arc = 90,
				Cooldown = 1.2
			},
			
			-- [[ SECCIÓN DE ANIMACIÓN AÑADIDA ]]
			-- IDs extraídos de tu script Animate.client.lua original.
			Animations = {
				Idle = "rbxassetid://507766388",
				Walk = "rbxassetid://507777826",
				Run = "rbxassetid://507767714",
				-- Los ataques se manejan como habilidades y no necesitan una animación base aquí.
			}
		},
		["Spawnmoon"] = {
			Price = 0,
			Icon = "rbxassetid://132619102920325",
			OwnedByDefault = false,
			Abilities = {"MoonsPresence", "GazeOfTheForgotten", "BloodMoon"},
			MaxHealth = 130,
			MaxStamina = 90,
			WalkSpeed = 16,
			AttackStats = {
				Damage = 60,
				Range = 6,
				Arc = 75,
				Cooldown = 1.5
			},
			
			-- [[ SECCIÓN DE ANIMACIÓN AÑADIDA ]]
			-- Usando las animaciones estándar por ahora. Puedes personalizarlas fácilmente aquí.
			Animations = {
				Idle = "rbxassetid://507766388",
				Walk = "rbxassetid://507777826",
				Run = "rbxassetid://507767714",
			},

			AbilityStats = {
				-- (Tus AbilityStats de Spawnmoon se mantienen intactas)
				MoonsPresence = { PanicRadius = 20, PanicTime = 3, StaminaBlockTime = 2 },
				GazeOfTheForgotten = { Cooldown = 18, ConeAngle = 45, TerrorDuration = 3, CameraLoss = 1, ForcedRun = 1.5, AbilityBlock = 3 },
				BloodMoon = { Cooldown = 100, Duration = 8, Opacity = 0.3, VisionReduction = 0.8 }
			}
		},
	},

	-- Clave principal para el rol de sobreviviente
	Survivor = {
		["Noob"] = {
			Price = 0,
			Icon = "rbxassetid://121105201966962",
			OwnedByDefault = true,
			Abilities = { "UnbreakableSpirit", "DummyDive", "FinalNoobazo" },
			MaxHealth = 160,
			WalkSpeed = 14,
			MaxStamina = 90,

			-- [[ SECCIÓN DE ANIMACIÓN AÑADIDA ]]
			-- IDs extraídos de tu script Animate.client.lua original.
			Animations = {
				Idle = "rbxassetid://507766388",
				Walk = "rbxassetid://507777826",
				Run = "rbxassetid://507767714",
				Jump = "rbxassetid://507765000",
				Fall = "rbxassetid://507767968",
			},

			AbilityStats = {
				-- (Tus AbilityStats de Noob se mantienen intactas)
				UnbreakableSpirit = { CheckRadius = 15, DamageReductionTiers = { 0.10, 0.20 } },
				DummyDive = {
					Cooldown = 12, DiveDuration = 0.3, DiveSpeed = 80, PushForce = 3000, SelfStunDuration = 5,
					Start = { { Action = "PlayAnimation", ID = "rbxassetid://102492173585132" }, 
					{ Action = "PlaySound", ID = "rbxassetid://147722227", Parent = "HumanoidRootPart" } },
					Impact = { { Action = "PlaySound", ID = "rbxassetid://7171761940", Parent = "HumanoidRootPart" } },
					Stun = { { Action = "PlayAnimation", ID = "rbxassetid://507771019", Looped = true, Duration = 5 }, 
					{ Action = "PlaySound", ID = "rbxassetid://155288625", Parent = "HumanoidRootPart" } }
				},
				FinalNoobazo = {
					Cooldown = 100, Duration = 8, HealPerSecond = 5, DamageReduction = 0.30,
					Start = { { Action = "SwapModel", ModelName = "Noob_Muscular", Folder = "CharacterModels" }, 
					{ Action = "PlayAnimation", ID = "rbxassetid://...Activate_Animation" }, 
					{ Action = "PlaySound", ID = "rbxassetid://...Activate_Sound", Looped = true, Name = "UltimateLoopSound", Parent = "HumanoidRootPart" },
					{ Action = "CreateVFX", ID = "rbxassetid://...Aura_Particle", Looped = true, Name = "UltimateAura", Parent = "HumanoidRootRootPart" } },
					End = { { Action = "StopEffects", Names = {"UltimateLoopSound", "UltimateAura"} }, { Action = "RevertModel" } }
				}
			}
		},
		["Spawnsun"] = {
			Price = 8,
			Icon = "rbxassetid://121105201966962",
			OwnedByDefault = false,
			Abilities = {"RadiantBond", "SolarSurge", "SunsBlessing"},
			MaxHealth = 100,
			MaxStamina = 120,
			WalkSpeed = 16,

			-- [[ SECCIÓN DE ANIMACIÓN AÑADIDA ]]
			-- Usando el set de animaciones estándar de sobreviviente.
			Animations = {
				Idle = "rbxassetid://507766388",
				Walk = "rbxassetid://507777826",
				Run = "rbxassetid://507767714",
				Jump = "rbxassetid://507765000",
				Fall = "rbxassetid://507767968",
			},

			AbilityStats = {
				-- (Tus AbilityStats de Spawnsun se mantienen intactas)
				RadiantBond = { HealPerSecond = 5, Range = 12, NoDamageTime = 3 },
				SolarSurge = { Cooldown = 15, Heal = 30, BuffReduction = 0.2, BuffDuration = 4, Range = 15 },
				SunsBlessing = { Cooldown = 90, Duration = 10, HealPerSecond = 10, Reduction = 0.3, Radius = 18 }
			}
		},
	}
}

return CharacterConfig