/*
 * Copyright � 2014 Duncan Fairley
 * Distributed under the GNU Affero General Public License, version 3.
 * Your changes must be made public.
 * For the full license text, see LICENSE.txt.
 */
var/EventScheduler/scheduler = new()
atom/var/tmp/list/StatusEffect/LStatusEffects

atom/proc/AddStatusEffect(StatusEffect/pStatusEffect)
	if(src.LStatusEffects)
		src.LStatusEffects += pStatusEffect
	else
		src.LStatusEffects = list(pStatusEffect)

atom/proc/RemoveStatusEffect(StatusEffect/pStatusEffect)
	if(src.LStatusEffects)
		src.LStatusEffects -= pStatusEffect
		if(!LStatusEffects.len)
			LStatusEffects = null
Event
	e_StatusEffect
		var/StatusEffect/AttachedStatusEffect

		New(StatusEffect/pStatusEffect)
			//Set Event's parent to the StatusEffect
			..()
			src.AttachedStatusEffect = pStatusEffect

		fire()
			..()
			if(AttachedStatusEffect)AttachedStatusEffect.Deactivate()

	AFKCheck

		fire()
			..()
			spawn()
				AFK_Train_Scan()
				scheduler.schedule(src, world.tick_lag * rand(9000, 12000)) // 15 to 20 minutes

	ClanWars

		fire()
			..()
			spawn()
				toggle_clanwars()
				scheduler.schedule(src, world.tick_lag * 604800 * 10) // 1 week

mob/proc/RevertTrans()
	if(src.LStatusEffects)
		var/StatusEffect/Transfiguration/S = locate() in src.LStatusEffects
		if(S)
			S.Deactivate()
atom/var/TransLastIcon
atom/var/TransLastIconState


atom/proc/findStatusEffect(var/type)
	return src.LStatusEffects ? locate(type) in src.LStatusEffects : 0
proc/issafezone(area/A)
		return safemode && !A.safezoneoverride && (!istype(A,/area/hogwarts/Duel_Arenas) && (istype(A,/area/hogwarts) || istype(A,/area/Diagon_Alley)))
proc/canUse(mob/Player/M,var/StatusEffect/cooldown=null,var/needwand=1,var/inarena=1,var/insafezone=1,var/inhogwarts=1,var/mob/Player/target=null,var/mpreq=0,var/againstocclumens=1,var/againstflying=1,var/againstcloaked=1,var/projectile=0)
	//Returns 1 if you can use the item/cast the spell. Also handles the printing of messages if you can't.
	if(!M.loc)
		M << "<b>You cannot use this in the void.</b>"
		return 0
	var/area/A = M.loc.loc
	if(M.z > SWAPMAP_Z && !inhogwarts)
		M << "<b>You cannot use this in a vault.</b>"
		return 0
	if(target && !insafezone && issafezone(target.loc.loc))
		M << "<b>[target] is inside a safezone.</b>"
		return 0
	if(!A.safezoneoverride)
		if(!inhogwarts && istype(M.loc.loc,/area/hogwarts))
			M << "<b>You can't use this inside hogwarts.</b>"
			return 0
		if(!insafezone && issafezone(M.loc.loc))
			M << "<b>You can't use this inside a safezone.</b>"
			return 0
		if(!inarena && istype(M.loc.loc,/area/arenas))
			M << "<b>You can't use this inside an arena.</b>"
			return 0
	if(target && !againstflying && target.flying)
		M << "<b>[target]'s broom is enhanced with anti-tampering charms.</b>"
		return 0
	if(!target && !againstflying && M.flying)
		M << "<b>Your broom is enhanced with anti-tampering charms.</b>"
		return 0
	if(target && !againstcloaked && (locate(/obj/items/wearable/invisibility_cloak) in target.Lwearing))
		M << "<b>Your spell doesn't manage to break the charms surrounding [target]'s cloak.</b>"
		return 0
	if(!target && !againstcloaked && (locate(/obj/items/wearable/invisibility_cloak) in M.Lwearing))
		M << "<b>Your cloak prevents this spell from being cast.</b>"
		return 0
	if(!againstocclumens && (target.occlumens || target.derobe || target.aurorrobe))
		M << "<b>A charm blocks your spell.</b>"
		return 0
	if(target && !target.key)
		M << "<b>You can only use this on other players.</b>"
		return 0
	if(needwand && !(locate(/obj/items/wearable/wands) in M:Lwearing))
		M << "<b>You must have a drawn wand to cast this.</b>"
		return 0
	if(M.Detention)
		M << "<b>You can't use this in Detention.</b>"
		return 0
	if(mpreq && M.MP < mpreq)
		M << "<b>You require [mpreq] MP to cast this.</b>"
		return 0
	if(cooldown)
		var/StatusEffect/S = M.findStatusEffect(cooldown)
		if(S)
			if(S.cantUseMsg(M))	//Says how long you need to wait to use the item/spell again
				return 0
	if(projectile)
		var/StatusEffect/S = M.findStatusEffect(/StatusEffect/DisableProjectiles)
		if(S)
			return 0
	return 1
StatusEffect
	Transfiguration
		var
			icon
			icon_state
		Activate()
			..()
			src.AttachedAtom.TransLastIcon = src.AttachedAtom.icon
			src.AttachedAtom.TransLastIconState = src.AttachedAtom.icon_state
			src.AttachedAtom.icon = src.icon
			src.AttachedAtom.icon_state = src.icon_state
		Deactivate()
			src.AttachedAtom.icon = src.AttachedAtom.TransLastIcon
			src.AttachedAtom.icon_state = src.AttachedAtom.TransLastIconState
			..()
	ClanWars
		ReinforcedDoors
			Activate()
				..()
				if(!isarea(AttachedAtom))
					world.log << "[AttachedAtom] is supposed to be an /area - /StatusEffect/ClanWars/ReinforcedDoors/Activate()"
				else
					if(istype(AttachedAtom,/area/DEHQ))
						for(var/mob/M in Players)if(M.DeathEater)
							M << "<font color=#E0E01D><b>The Deatheater HQ doors have been reinforced.</b></font>"
					else if(istype(AttachedAtom,/area/AurorHQ))
						for(var/mob/M in Players)if(M.Auror)
							M << "<font color=#E0E01D><b>The Auror HQ doors have been reinforced.</b></font>"
					for(var/obj/brick2door/clandoor/D in AttachedAtom)//An /area
						D.MHP = 2*initial(D.MHP)
			Deactivate()
				if(!isarea(AttachedAtom))
					world.log << "[AttachedAtom] is supposed to be an /area - /StatusEffect/ClanWars/ReinforcedDoors/Deactivate()"
				else
					for(var/obj/brick2door/clandoor/D in AttachedAtom)//An /area
						D.MHP = initial(D.MHP)
						if(D.HP > D.MHP) D.HP = D.HP
				..()
	GotSpellpoint
	Poisoned
	SteppedOnPoop
	Flying
	UsedEpiskey
	UsedTarantallegra
	UsedCrucio
	Summoned
	Decloaked
	Knockedfrombroom
	UsedFerulaToHeal
	UsedFerula
	UsedLevicorpus
	UsedEvanesco
	UsedEvanesca
	UsedClanAbilities
	UsedIncindia
	UsedObliviate
	UsedStun
	UsedFlagrate
	UsedTransfiguration
	UsedConjunctivis
	UsedMelofors
	UsedPortus
	UsedMeditate
	UsedExpelliarmus
	UsedHalloweenBucket
	UsedSonic
	UsedSnowRing
	UsedArcesso
	UsedProtego
	UsedShelleh
	Permoveo
	UsedDisperse
	DepulsoText
	DisableProjectiles
	KilledPlayer
	UsedRepel
	UsedRiddikulus
	UsedGMHelp

	Lamps
		var/tmp/obj/items/lamps/lamp

		Farming

		DropRate
			var/rate
			Double
				rate = 2
			Triple
				rate = 3
			Quadaple
				rate = 4

		Exp
			var/rate
			Double
				rate = 2
			Triple
				rate = 3
			Quadaple
				rate = 4

		Gold
			var/rate
			Double
				rate = 2
			Triple
				rate = 3
			Quadaple
				rate = 4

		Activate()
			var/found = FALSE
			for(var/StatusEffect/Lamps/s in AttachedAtom.LStatusEffects)
				if(s != src && istype(s, /StatusEffect/Lamps))
					found = TRUE
					break
			if(found)
				AttachedAtom << errormsg("You can only use one lamp at a time.")
				Deactivate()
			else
				AttachedAtom << infomsg("You feel the warmth of [lamp]'s magical light.")
				lamp.icon_state = "active"
				..()

		Deactivate()
			AttachedAtom << infomsg("[lamp]'s effect fades.")
			lamp.seconds = round(scheduler.time_to_fire(AttachedEvent)/10)
			if(lamp.seconds <= 0)
				AttachedAtom << errormsg("[lamp] disappears into thin air.")
				del lamp
				AttachedAtom:Resort_Stacking_Inv()
			else
				var/min = round(lamp.seconds / 60)
				var/sec = lamp.seconds-(min*60)
				var/time = ""
				if(min) time = "[min] minutes"
				if(sec)
					if(min) time += " and "
					time += "[sec] seconds."
				lamp.desc = "[initial(lamp.desc)] Time Remaining: [time]"
				lamp.icon_state = "inactive"
			..()

		New(atom/pAttachedAtom,t,obj/items/lamps/p)
			lamp = p
			.=..()

	var/Event/e_StatusEffect/AttachedEvent	//Not required - Contains /Event/e_StatusEffect to automatically cancel the StatusEffect
	var/atom/AttachedAtom	//Required - Contains the /atom which the StatusEffect is attached to
	proc
		cantUseMsg(M)
			//Return 1 if it's a genuine event
			var/timeleft = round(scheduler.time_to_fire(AttachedEvent)/10)
			if(timeleft < 0)
				//scheduler.cancel(src.AttachedEvent)
				del(src)
				return 0
			if(timeleft == 0) timeleft = 1
			M << "<b>This can't be used for another [timeleft] second[timeleft==1 ? "" : "s"].</b>"
			return 1
	New(atom/pAttachedAtom,t)
		//Attaches a StatusEffect to an atom - if t is specified, an /Event is attached also
		src.AttachedAtom = pAttachedAtom
		src.AttachedAtom.AddStatusEffect(src)
		if(t)
			src.AttachedEvent = new(src)
			scheduler.schedule(src.AttachedEvent,world.tick_lag * t * 10)//Accomodate for non-one ticklags.
		Activate()

	Del()
		//Deletes AttachedEvent if exists
		if(src.AttachedEvent)
			scheduler.cancel(src.AttachedEvent)
		..()

	proc
		Activate()
			//Called when /StatusEffect is setup
		Deactivate()
			//Called when the timer in an AttachedEvent runs out
			if(AttachedAtom)//If they're still logged in
				src.AttachedAtom.RemoveStatusEffect(src)
			del(src)