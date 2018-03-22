#define TAB_ANALYSIS 1
#define TAB_EXPERIMENT 2
#define TAB_DATABASE 3

/obj/machinery/computer/pandemic
	name = "PanD.E.M.I.C 2200"
	desc = "Used to work with viruses."
	density = 1
	anchored = 1
	icon = 'icons/obj/chemical.dmi'
	icon_state = "mixer0"
	circuit = /obj/item/circuitboard/computer/pandemic
	use_power = 1
	idle_power_usage = 20
	resistance_flags = ACID_PROOF
	var/virusfood_amount = 0
	var/mutagen_amount = 0
	var/plasma_amount = 0
	var/synaptizine_amount = 0
	var/synaptizinevirusfood_amount = 0
	var/mutagenvirusfood_amount = 0
	var/sugarvirusfood_amount = 0
	var/weakplasmavirusfood_amount = 0
	var/plasmavirusfood_amount = 0
	var/uraniumvirusfood_amount = 0
	var/uraniumplasmavirusfood_unstable_amount = 0
	var/uraniumplasmavirusfood_stable_amount = 0
	var/formaldehyde_amount = 0
	var/list/new_diseases = list()
	var/list/new_symptoms = list()
	var/list/new_cures = list()
	var/tab_open = TAB_ANALYSIS //the magic of defines!
	var/temp_html = ""
	var/wait = null
	var/waittime = 5
	var/obj/item/reagent_containers/glass/beaker = null

/obj/machinery/computer/pandemic/Initialize()
	. = ..()
	update_icon()

/obj/machinery/computer/pandemic/proc/GetVirusByIndex(var/index)
	if(beaker && beaker.reagents)
		if(beaker.reagents.reagent_list.len)
			var/datum/reagent/blood/BL = locate() in beaker.reagents.reagent_list
			if(BL)
				if(BL.data && BL.data["viruses"])
					var/list/viruses = BL.data["viruses"]
					return viruses[index]
	return null

/obj/machinery/computer/pandemic/proc/GetResistancesByIndex(var/index)
	if(beaker && beaker.reagents)
		if(beaker.reagents.reagent_list.len)
			var/datum/reagent/blood/BL = locate() in beaker.reagents.reagent_list
			if(BL)
				if(BL.data && BL.data["resistances"])
					var/list/resistances = BL.data["resistances"]
					return resistances[index]
	return null

/obj/machinery/computer/pandemic/proc/GetVirusTypeByIndex(var/index)
	var/datum/disease/D = GetVirusByIndex(index)
	if(D)
		return D.GetDiseaseID()
	return null


/obj/machinery/computer/pandemic/proc/replicator_cooldown(var/waittime)
	wait = 1

/obj/machinery/computer/pandemic/proc/get_viruses_data(datum/reagent/blood/B)
	. = list()
	var/list/V = B.get_diseases()
	var/index = 1
	for(var/virus in V)
		var/datum/disease/D = virus
		if(!istype(D) || D.visibility_flags & HIDDEN_PANDEMIC)
			continue

		var/list/this = list()
		this["name"] = D.name
		if(istype(D, /datum/disease/advance))
			var/datum/disease/advance/A = D
			var/disease_name = SSdisease.get_disease_name(A.GetDiseaseID())
			if(disease_name == "Unknown")
				this["can_rename"] = TRUE
			this["name"] = disease_name
			this["is_adv"] = TRUE
			this["symptoms"] = list()
			var/symptom_index = 1
			for(var/symptom in A.symptoms)
				var/datum/symptom/S = symptom
				var/list/this_symptom = list()
				this_symptom["name"] = S.name
				this_symptom["sym_index"] = symptom_index
				symptom_index++
				this["symptoms"] += list(this_symptom)
			this["resistance"] = A.totalResistance()
			this["stealth"] = A.totalStealth()
			this["stage_speed"] = A.totalStageSpeed()
			this["transmission"] = A.totalTransmittable()
		this["index"] = index++
		this["agent"] = D.agent
		this["description"] = D.desc || "none"
		this["spread"] = D.spread_text || "none"
		this["cure"] = D.cure_text || "none"

		. += list(this)

/obj/machinery/computer/pandemic/proc/get_symptom_data(datum/symptom/S)
	. = list()
	var/list/this = list()
	this["name"] = S.name
	this["desc"] = S.desc
	this["stealth"] = S.stealth
	this["resistance"] = S.resistance
	this["stage_speed"] = S.stage_speed
	this["transmission"] = S.transmittable
	this["level"] = S.level
	this["neutered"] = S.neutered
	this["threshold_desc"] = S.threshold_desc
	. += this

/obj/machinery/computer/pandemic/proc/get_resistance_data(datum/reagent/blood/B)
	. = list()
	if(!islist(B.data["resistances"]))
		return
	var/list/resistances = B.data["resistances"]
	for(var/id in resistances)
		var/list/this = list()
		var/datum/disease/D = SSdisease.archive_diseases[id]
		if(D)
			this["id"] = id
			this["name"] = D.name

		. += list(this)

/obj/machinery/computer/pandemic/proc/reset_replicator_cooldown()
	wait = FALSE
	update_icon()
	spawn(waittime)
		src.wait = null
		update_icon()
		playsound(src.loc, 'sound/machines/ping.ogg', 30, 1)

/obj/machinery/computer/pandemic/update_icon()
	if(stat & BROKEN)
		icon_state = (src.beaker?"mixer1_b":"mixer0_b")
		return

	icon_state = "mixer[(beaker)?"1":"0"][(powered()) ? "" : "_nopower"]"

	if(wait)
		overlays.Cut()
	else
		overlays += "waitlight"

/obj/machinery/computer/pandemic/Topic(href, href_list)
	if(..())
		return
	usr.set_machine(src)
	if (href_list["cure"])
		if(!src.wait)
			var/obj/item/reagent_containers/glass/bottle/B = new/obj/item/reagent_containers/glass/bottle(src.loc)
			if(B)
				B.pixel_x = rand(-3, 3)
				B.pixel_y = rand(-3, 3)
				var/vaccine_type = new_cures[text2num(href_list["cure"])]
				if(vaccine_type)
					if(!ispath(vaccine_type))
						if(SSdisease.archive_diseases[vaccine_type])
							var/datum/disease/D = SSdisease.archive_diseases[vaccine_type]
							B.name = "[D.name] vaccine bottle"
							B.reagents.add_reagent("vaccine", 15, list(vaccine_type))
							replicator_cooldown(200)
					else
						var/datum/disease/D = vaccine_type
						B.name = "[D.name] vaccine bottle"
						B.reagents.add_reagent("vaccine", 15, list(vaccine_type))
						replicator_cooldown(200)
		else
			src.temp_html = "The replicator is not ready yet."
		src.updateUsrDialog()
		return

	else if (href_list["virus"])
		if(!wait)
			var/datum/disease/D = new_diseases[text2num(href_list["virus"])]
			if(!D)
				return
			var/name = stripped_input(usr,"Name:","Name the culture",D.name,MAX_NAME_LEN)
			if(name == null || wait)
				return
			var/obj/item/reagent_containers/glass/bottle/B = new/obj/item/reagent_containers/glass/bottle(src.loc)
			B.icon_state = "bottle3"
			B.pixel_x = rand(-3, 3)
			B.pixel_y = rand(-3, 3)
			replicator_cooldown(50)
			var/list/data = list("viruses"=list(D))
			B.name = "[name] culture bottle"
			B.desc = "A small bottle. Contains [D.agent] culture in synthblood medium."
			B.reagents.add_reagent("blood",20,data)
			src.updateUsrDialog()
		else
			src.temp_html = "The replicator is not ready yet."
		src.updateUsrDialog()
		return


	else if(href_list["name_disease"])
		var/new_name = stripped_input(usr, "Name the Disease", "New Name", "", MAX_NAME_LEN)
		if(!new_name)
			return
		if(..())
			return
		var/id = GetVirusTypeByIndex(text2num(href_list["name_disease"]))
		if(SSdisease.archive_diseases[id])
			var/datum/disease/advance/A = SSdisease.archive_diseases[id]
			A.AssignName(new_name)
			for(var/datum/disease/advance/AD in SSdisease.active_diseases)
				AD.Refresh()
			if(beaker && beaker.reagents && beaker.reagents.reagent_list.len)
				var/datum/reagent/blood/BL = locate() in beaker.reagents.reagent_list
				if(BL)
					if(BL.data && BL.data["viruses"])
						var/list/viruses = BL.data["viruses"]
						for(var/datum/disease/advance/AD in viruses)
							if(AD.id == id)
								AD.Refresh()
		src.updateUsrDialog()

	else if (href_list["eject"])
		if(beaker)
			var/obj/item/reagent_containers/glass/B = beaker
			B.loc = loc
			beaker = null
			icon_state = "mixer0"
			src.updateUsrDialog()
			return

	else if (href_list["tab_open"])
		tab_open = text2num(href_list["tab_open"]) //fucking text
		src.updateUsrDialog()
		return

	else if(href_list["chem_choice"])
		if(!beaker) return
		switch(href_list["chem_choice"]) //holy copypasta batman
			if("virusfood")
				if(virusfood_amount>0)
					beaker.reagents.add_reagent("virusfood",min(beaker.reagents.maximum_volume-beaker.reagents.total_volume,1))
					virusfood_amount -= 1
					usr << "Virus Food administered."
				else
					usr << "Not enough Virus Food stored!"
			if("mutagen")
				if(mutagen_amount>0)
					beaker.reagents.add_reagent("mutagen",min(beaker.reagents.maximum_volume-beaker.reagents.total_volume,1))
					mutagen_amount -= 1
					usr << "Unstable Mutagen administered."
				else
					usr << "Not enough Unstable Mutagen stored!"
			if("plasma")
				if(plasma_amount>0)
					beaker.reagents.add_reagent("plasma",min(beaker.reagents.maximum_volume-beaker.reagents.total_volume,1))
					plasma_amount -= 1
					usr << "Plasma administered."
				else
					usr << "Not enough Plasma stored!"
			if("synaptizine")
				if(synaptizine_amount>0)
					beaker.reagents.add_reagent("synaptizine",min(beaker.reagents.maximum_volume-beaker.reagents.total_volume,1))
					synaptizine_amount -= 1
					usr << "Synaptizine administered."
				else
					usr << "Not enough Synaptizine!"
			if("synaptizinevirusfood")
				if(synaptizinevirusfood_amount>0)
					beaker.reagents.add_reagent("synaptizinevirusfood",min(beaker.reagents.maximum_volume-beaker.reagents.total_volume,1))
					synaptizinevirusfood_amount -= 1
					usr << "Virus rations administered."
				else
					usr << "Not enough Virus rations!"
			if("mutagenvirusfood")
				if(mutagenvirusfood_amount>0)
					beaker.reagents.add_reagent("mutagenvirusfood",min(beaker.reagents.maximum_volume-beaker.reagents.total_volume,1))
					mutagenvirusfood_amount -= 1
					usr << "Mutagenic agar administered."
				else
					usr << "Not enough Mutagenic agar!"
			if("sugarvirusfood")
				if(sugarvirusfood_amount>0)
					beaker.reagents.add_reagent("sugarvirusfood",min(beaker.reagents.maximum_volume-beaker.reagents.total_volume,1))
					sugarvirusfood_amount -= 1
					usr << "Sucrose agar administered."
				else
					usr << "Not enough Sucrose agar!"
			if("weakplasmavirusfood")
				if(weakplasmavirusfood_amount>0)
					beaker.reagents.add_reagent("weakplasmavirusfood",min(beaker.reagents.maximum_volume-beaker.reagents.total_volume,1))
					weakplasmavirusfood_amount -= 1
					usr << "Weakened virus plasma administered."
				else
					usr << "Not enough Weakened virus plasma!"
			if("plasmavirusfood")
				if(plasmavirusfood_amount>0)
					beaker.reagents.add_reagent("plasmavirusfood",min(beaker.reagents.maximum_volume-beaker.reagents.total_volume,1))
					plasmavirusfood_amount -= 1
					usr << "Virus plasma administered."
				else
					usr << "Not enough Virus plasma!"
			if("uraniumvirusfood")
				if(uraniumvirusfood_amount>0)
					beaker.reagents.add_reagent("uraniumvirusfood",min(beaker.reagents.maximum_volume-beaker.reagents.total_volume,1))
					uraniumvirusfood_amount -= 1
					usr << "Decaying uranium gel administered."
				else
					usr << "Not enough Decaying uranium gel!"
			if("uraniumplasmavirusfood_unstable")
				if(uraniumplasmavirusfood_unstable_amount>0)
					beaker.reagents.add_reagent("uraniumplasmavirusfood_unstable",min(beaker.reagents.maximum_volume-beaker.reagents.total_volume,1))
					uraniumplasmavirusfood_unstable_amount -= 1
					usr << "Unstable uranium gel administered."
				else
					usr << "Not enough Unstable uranium gel!"
			if("uraniumplasmavirusfood_stable")
				if(uraniumplasmavirusfood_stable_amount>0)
					beaker.reagents.add_reagent("uraniumplasmavirusfood_stable",min(beaker.reagents.maximum_volume-beaker.reagents.total_volume,1))
					uraniumplasmavirusfood_stable_amount -= 1
					usr << "Stable uranium gel administered."
				else
					usr << "Not enough Stable uranium gel!"
			if("formaldehyde")
				if(formaldehyde_amount>0)
					beaker.reagents.add_reagent("formaldehyde",min(beaker.reagents.maximum_volume-beaker.reagents.total_volume,1))
					uraniumplasmavirusfood_stable_amount -= 1
					usr << "Formaldehyde administered."
				else
					usr << "Not enough Formaldehyde!"
		src.updateUsrDialog()
		return
	else if(href_list["chem_transfer"])
		if(!beaker) return
		var/input_amt = input("Please input the amount to transfer", name) as num
		if(..()) //test to see if they haven't moved away
			return
		var/transfer_amt = min(beaker.reagents.maximum_volume-beaker.reagents.total_volume, input_amt)
		switch(href_list["chem_transfer"])
			if("virusfood")
				beaker.reagents.add_reagent("virusfood", transfer_amt)
				virusfood_amount -= transfer_amt
			if("mutagen")
				beaker.reagents.add_reagent("mutagen", transfer_amt)
				mutagen_amount -= transfer_amt
			if("plasma")
				beaker.reagents.add_reagent("plasma", transfer_amt)
				plasma_amount -= transfer_amt
			if("synaptizine")
				beaker.reagents.add_reagent("synaptizine", transfer_amt)
				synaptizine_amount -= transfer_amt
			if("synaptizinevirusfood")
				beaker.reagents.add_reagent("synaptizinevirusfood", transfer_amt)
				synaptizinevirusfood_amount -= transfer_amt
			if("mutagenvirusfood")
				beaker.reagents.add_reagent("mutagenvirusfood", transfer_amt)
				mutagenvirusfood_amount -= transfer_amt
			if("sugarvirusfood")
				beaker.reagents.add_reagent("sugarvirusfood", transfer_amt)
				sugarvirusfood_amount -= transfer_amt
			if("weakplasmavirusfood")
				beaker.reagents.add_reagent("weakplasmavirusfood", transfer_amt)
				weakplasmavirusfood_amount -= transfer_amt
			if("plasmavirusfood")
				beaker.reagents.add_reagent("plasmavirusfood", transfer_amt)
				plasmavirusfood_amount -= transfer_amt
			if("uraniumvirusfood_amount")
				beaker.reagents.add_reagent("uraniumvirusfood_amount", transfer_amt)
				uraniumvirusfood_amount-= transfer_amt
			if("uraniumplasmavirusfood_unstable")
				beaker.reagents.add_reagent("uraniumplasmavirusfood_unstable", transfer_amt)
				uraniumplasmavirusfood_unstable_amount -= transfer_amt
			if("uraniumplasmavirusfood_stable")
				beaker.reagents.add_reagent("uraniumplasmavirusfood_stable", transfer_amt)
				uraniumplasmavirusfood_stable_amount -= transfer_amt
			if("formaldehyde")
				beaker.reagents.add_reagent("formaldehyde", transfer_amt)
				formaldehyde_amount -= transfer_amt
	else if(href_list["empty_beaker"])
		if(!beaker) return
		beaker.reagents.clear_reagents()

	else if(href_list["update_virus"])
		upload_virus(usr)
	else if(href_list["update_cure"])
		upload_vaccine(usr)
	else if(href_list["delete_virus"])
		delete_virus(href_list["delete_virus"])
	else if(href_list["delete_cure"])
		delete_vaccine(href_list["delete_cure"])
	else
		usr << browse(null, "window=pandemic")
		src.updateUsrDialog()
		return

	src.updateUsrDialog()



	src.add_fingerprint(usr)
	return

/obj/machinery/computer/pandemic/attack_hand(mob/user as mob)
	if(..())
		return
	user.set_machine(src)
	var/dat = ""
	dat += "<A href='?src=\ref[src];tab_open=1'>Analysis</a>"
	dat += "<A href='?src=\ref[src];tab_open=2'>Experiment</a>"
	dat += "<A href='?src=\ref[src];tab_open=3'>Database</a><br><hr><BR>"

	switch(tab_open)
		if(TAB_ANALYSIS)
			if(!beaker)
				dat += "<b>No beaker inserted.</b><BR>"

			else
				var/datum/reagents/R = beaker.reagents
				var/datum/reagent/blood/Blood = null
				for(var/datum/reagent/blood/B in R.reagent_list)
					if(B)
						Blood = B
						break
				if(!R.total_volume||!R.reagent_list.len)
					dat += "<b>The beaker is empty</b><BR>"
				else if(!Blood)
					dat += "<b>No blood sample found in beaker.</b>"
				else if(!Blood.data)
					dat += "<b>No blood data found in beaker.</b>"
				else
					if(Blood.data["viruses"])
						var/list/vir = Blood.data["viruses"]
						if(vir.len)
							var/i = 0
							for(var/datum/disease/D in Blood.data["viruses"])
								i++
								if(!(D.visibility_flags & HIDDEN_PANDEMIC))

									if(istype(D, /datum/disease/advance))

										var/datum/disease/advance/A = D
										D = SSdisease.archive_diseases[A.GetDiseaseID()]
										if(D && D.name == "Unknown")
											dat += "<b><a href='?src=\ref[src];name_disease=[i]'>Name Disease</a></b><BR>"

									if(!D)
										CRASH("We weren't able to get the advance disease from the archive.")

									dat += "<b>Disease Agent:</b> [D?"[D.agent]":"none"]<BR>"
									dat += "<b>Common name:</b> [(D.name||"none")]<BR>"
									dat += "<b>Description: </b> [(D.desc||"none")]<BR>"
									dat += "<b>Spread:</b> [(D.spread_text||"none")]<BR><hr><br>"
									dat += "<b>Possible cure:</b> [(D.cure_text||"none")]<BR>"

									if(istype(D, /datum/disease/advance))
										var/datum/disease/advance/A = D
										dat += "<b>Symptoms:</b> "
										var/english_symptoms = list()
										for(var/datum/symptom/S in A.symptoms)
											english_symptoms += S.name
										dat += english_list(english_symptoms)
										dat += "<BR><A href='?src=\ref[src];update_virus=1'>Upload to database</a><BR>"

								else
									dat += "<b>No detectable virus in the sample.</b>"
					else
						dat += "<b>No detectable virus in the sample.</b>"
					dat += "<BR><hr><BR><b>Contains antibodies to:</b> "
					if(Blood.data["resistances"])
						var/list/res = Blood.data["resistances"]
						if(res.len)
							dat += "<ul>"
							for(var/type in Blood.data["resistances"])
								var/disease_name = "Unknown"
								if(!ispath(type))
									var/datum/disease/advance/A = SSdisease.archive_diseases[type]
									if(A)
										disease_name = A.name
								else
									var/datum/disease/D = new type(0, null)
									disease_name = D.name
								dat += "<li>[disease_name]</li>"
							dat += "</ul><BR>"
							dat += "<BR><A href='?src=\ref[src];update_cure=1'>Upload to database</a><BR>"
						else
							dat += "nothing<BR>"
					else
						dat += "nothing<BR>"
					dat += "<hr><BR><A href='?src=\ref[src];empty_beaker=1'>Empty beaker</A>"
		if(TAB_EXPERIMENT)
			dat += "<b>Available Chems:</b><br>"
			dat += "Virus Food: [virusfood_amount].<br>"
			dat += "Unstable Mutagen: [mutagen_amount].<br>"
			dat += "Plasma: [plasma_amount].<br>"
			dat += "Synaptizine: [synaptizine_amount].<br>"
			dat += "Virus rations: [synaptizinevirusfood_amount].<br>"
			dat += "Mutagenic agar: [mutagenvirusfood_amount].<br>"
			dat += "Sucrose agar: [sugarvirusfood_amount].<br>"
			dat += "Weakened virus plasma: [weakplasmavirusfood_amount].<br>"
			dat += "Virus plasma: [plasmavirusfood_amount].<br>"
			dat += "Decaying uranium gel: [uraniumvirusfood_amount].<br>"
			dat += "Unstable uranium gel: [uraniumplasmavirusfood_unstable_amount].<br>"
			dat += "Stable uranium gel: [uraniumplasmavirusfood_stable_amount].<br>"
			dat += "Formaldehyde: [formaldehyde_amount].<br><hr><br>"

			if(!beaker)
				dat += "<b>No beaker inserted.</b><BR>"
			else
				var/datum/reagents/R = beaker.reagents
				var/datum/reagent/blood/Blood = null
				for(var/datum/reagent/blood/B in R.reagent_list)
					if(B)
						Blood = B
						break
				if(!R.total_volume||!R.reagent_list.len)
					dat += "<b>The beaker is empty</b><BR>"
				else if(!Blood)
					dat += "<b>No blood sample found in beaker.</b>"
				else if(!Blood.data)
					dat += "<b>No blood data found in beaker.</b>"
				else
					if(Blood.data["viruses"])
						var/list/vir = Blood.data["viruses"]
						if(vir.len)
							for(var/datum/disease/D in Blood.data["viruses"])
								if(!(D.visibility_flags & HIDDEN_PANDEMIC))
									if(!D)
										CRASH("We weren't able to get the advance disease from the archive.")
									if(istype(D, /datum/disease/advance))
										var/datum/disease/advance/A = D
										dat += "<b>Symptoms:</b> "
										var/english_symptoms = list()
										dat += "<ul>"
										for(var/datum/symptom/S in A.symptoms)
											english_symptoms += S.name
										dat += english_list(english_symptoms)+"<br>"
										dat += "</ul>"

								else
									dat += "<b>No detectable virus in the sample.</b>"
				dat += "<br><hr><br>"
				dat += "<b>Inject Sample with:</b><br>"
				dat += "<A href='?src=\ref[src];chem_choice=virusfood'>Virus Food</a><BR>"
				dat += "<A href='?src=\ref[src];chem_choice=mutagen'>Unstable Mutagen</a><BR>"
				dat += "<A href='?src=\ref[src];chem_choice=plasma'>Plasma</a><BR>"
				dat += "<A href='?src=\ref[src];chem_choice=synaptizine'>Synaptizine</a><BR>"
				dat += "<A href='?src=\ref[src];chem_choice=synaptizinevirusfood'>Virus rations</a><BR>"
				dat += "<A href='?src=\ref[src];chem_choice=mutagenvirusfood'>Mutagenic agar</a><BR>"
				dat += "<A href='?src=\ref[src];chem_choice=sugarvirusfood'>Sucrose agar</a><BR>"
				dat += "<A href='?src=\ref[src];chem_choice=weakplasmavirusfood'>Weakened virus plasma</a><BR>"
				dat += "<A href='?src=\ref[src];chem_choice=plasmavirusfood'>Virus plasma</a><BR>"
				dat += "<A href='?src=\ref[src];chem_choice=uraniumvirusfood'>Decaying uranium gel</a><BR>"
				dat += "<A href='?src=\ref[src];chem_choice=uraniumplasmavirusfood_unstable'>Unstable uranium gel</a><BR>"
				dat += "<A href='?src=\ref[src];chem_choice=uraniumplasmavirusfood_stable'>Stable uranium gel</a><BR>"
				dat += "<A href='?src=\ref[src];chem_choice=formaldehyde'>formaldehyde</a><BR>"

				dat += "<b>Transfer to beaker:</b><br>"
				dat += "<A href='?src=\ref[src];chem_transfer=virusfood'>Virus Food</a><BR>"
				dat += "<A href='?src=\ref[src];chem_transfer=mutagen'>Unstable Mutagen</a><BR>"
				dat += "<A href='?src=\ref[src];chem_transfer=plasma'>Plasma</a><BR>"
				dat += "<A href='?src=\ref[src];chem_transfer=synaptizine'>Synaptizine</a><BR>"
				dat += "<A href='?src=\ref[src];chem_transfer=synaptizinevirusfood'>Virus rations</a><BR>"
				dat += "<A href='?src=\ref[src];chem_transfer=mutagenvirusfood'>Mutagenic agar</a><BR>"
				dat += "<A href='?src=\ref[src];chem_transfer=sugarvirusfood'>Sucrose agar</a><BR>"
				dat += "<A href='?src=\ref[src];chem_transfer=weakplasmavirusfood'>Weakened virus plasma</a><BR>"
				dat += "<A href='?src=\ref[src];chem_transfer=plasmavirusfood'>Virus plasma</a><BR>"
				dat += "<A href='?src=\ref[src];chem_transfer=uraniumvirusfood'>Decaying uranium gel</a><BR>"
				dat += "<A href='?src=\ref[src];chem_transfer=uraniumplasmavirusfood_unstable'>Unstable uranium gel</a><BR>"
				dat += "<A href='?src=\ref[src];chem_transfer=uraniumplasmavirusfood_stable'>Stable uranium gel</a><BR>"
				dat += "<A href='?src=\ref[src];chem_transfer=formaldehyde'>Formaldehyde</a><BR>"

		if(TAB_DATABASE)
			dat += "<b>Database:</b><BR><hr>"
			var/loop = 0
			dat += "<br><b>Diseases:</b>"
			dat += "<A href='?src=\ref[src];update_virus=1'>Update</a><BR><hr>"
			for(var/datum/disease/type in new_diseases)
				loop++
				dat += "[type.name] "
				dat += "<li><A href='?src=\ref[src];virus=[loop]'>- <i>Make</i></A> <A href='?src=\ref[src];delete_virus=[loop]'>- <i>Delete</i></A><br></li>"
			loop = 0
			dat += "<br><b>Vaccines:</b>"
			dat += "<A href='?src=\ref[src];update_cure=1'>Update</a><BR><hr>"
			for(var/type in new_cures)
				loop++
				if(!ispath(type)) //Is an advanced disease
					var/datum/disease/DD = SSdisease.archive_diseases[type]
					dat += "[DD.name] "
				else
					var/datum/disease/gn = new type(0, null)
					dat += "[gn.name] "
				dat += "<li><A href='?src=\ref[src];cure=[loop]'> - <i>Make</i></A> <A href='?src=\ref[src];delete_vaccine=[loop]'>- <i>Delete</i></A><br></li>"

	dat += "<hr><BR><A href='?src=\ref[src];eject=1'>Eject beaker</A>"

	var/datum/browser/popup = new(user, "pandemic", "PanD.E.M.I.C 2200")
	popup.set_content(dat)
	popup.set_title_image(user.browse_rsc_icon(src.icon, src.icon_state))
	popup.open(1)
	return

/obj/machinery/computer/pandemic/attackby(var/obj/I as obj, var/mob/user as mob, params)
	if(istype(I, /obj/item/reagent_containers/glass))
		. = 1 //no afterattack
		if(stat & (NOPOWER|BROKEN))
			return
		if(beaker)
			to_chat(user, "<span class='warning'>A container is already loaded into [src]!</span>")
			return
		if(!user.transferItemToLoc(I, src))
			return


		for(var/datum/reagent/R in I.reagents.reagent_list)
			if(R.id == "virusfood")
				virusfood_amount += R.volume
				I.reagents.remove_reagent("virusfood",R.volume)
				user << "You add the Virus Food into the machine!"
				src.updateUsrDialog()
				return
			if(R.id == "mutagen")
				mutagen_amount += R.volume
				I.reagents.remove_reagent("mutagen",R.volume)
				user << "You add the Unstable Mutagen into the machine!"
				src.updateUsrDialog()
				return
			if(R.id == "plasma")
				plasma_amount += R.volume
				I.reagents.remove_reagent("plasma",R.volume)
				user << "You add the Plasma into the machine!"
				src.updateUsrDialog()
				return
			if(R.id == "synaptizine")
				synaptizine_amount += R.volume
				I.reagents.remove_reagent("synaptizine",R.volume)
				user << "You add the Synaptizine into the machine!"
				src.updateUsrDialog()
				return
			if(R.id == "synaptizinevirusfood")
				synaptizinevirusfood_amount += R.volume
				I.reagents.remove_reagent("synaptizinevirusfood",R.volume)
				user << "You add the Virus rations into the machine!"
				src.updateUsrDialog()
				return
			if(R.id == "mutagenvirusfood")
				mutagenvirusfood_amount += R.volume
				I.reagents.remove_reagent("mutagenvirusfood",R.volume)
				user << "You add the Mutagenic agar into the machine!"
				src.updateUsrDialog()
				return
			if(R.id == "sugarvirusfood")
				sugarvirusfood_amount += R.volume
				I.reagents.remove_reagent("sugarvirusfood",R.volume)
				user << "You add the Sucrose agar into the machine!"
				src.updateUsrDialog()
				return
			if(R.id == "weakplasmavirusfood")
				weakplasmavirusfood_amount += R.volume
				I.reagents.remove_reagent("weakplasmavirusfood",R.volume)
				user << "You add the Weakened virus plasma into the machine!"
				src.updateUsrDialog()
				return
			if(R.id == "plasmavirusfood")
				plasmavirusfood_amount += R.volume
				I.reagents.remove_reagent("plasmavirusfood",R.volume)
				user << "You add the Virus plasma into the machine!"
				src.updateUsrDialog()
				return
			if(R.id == "uraniumvirusfood")
				uraniumvirusfood_amount += R.volume
				I.reagents.remove_reagent("uraniumvirusfood",R.volume)
				user << "You add the Decaying uranium gel into the machine!"
				src.updateUsrDialog()
				return
			if(R.id == "uraniumplasmavirusfood_unstable")
				uraniumplasmavirusfood_unstable_amount += R.volume
				I.reagents.remove_reagent("uraniumplasmavirusfood_unstable",R.volume)
				user << "You add the Unstable uranium gel into the machine!"
				src.updateUsrDialog()
				return
			if(R.id == "uraniumplasmavirusfood_stable")
				uraniumplasmavirusfood_stable_amount += R.volume
				I.reagents.remove_reagent("uraniumplasmavirusfood_stable",R.volume)
				user << "You add the Stable uranium gel into the machine!"
				src.updateUsrDialog()
				return
			if(R.id == "formaldehyde")
				formaldehyde_amount += R.volume
				I.reagents.remove_reagent("formaldehyde",R.volume)
				user << "You add the Formaldehyde into the machine!"
				src.updateUsrDialog()
				return
		if(src.beaker)
			user << "A beaker is already loaded into the machine."
			return
		beaker =  I
		beaker.loc = src
		to_chat(user, "<span class='notice'>You add the beaker to the machine.</span>")
		updateUsrDialog()
		icon_state = "mixer1"

	else if(istype(I, /obj/item/screwdriver))
		if(src.beaker)
			beaker.loc = get_turf(src)
		..()
		return
	else
		..()
	return
/obj/machinery/computer/pandemic/proc/upload_virus(var/mob/user)
	if(beaker && beaker.reagents)
		if(beaker.reagents.reagent_list.len)
			var/datum/reagent/blood/BL = locate() in beaker.reagents.reagent_list
			if(BL)
				if(BL.data && BL.data["viruses"])
					var/list/viruses = BL.data["viruses"]
					for(var/datum/disease/D in viruses)
						var/d_test = 1
						for(var/datum/disease/DT in new_diseases) //we scan for the desease itself to add to the list
							if(D.IsSame(DT))
								if(DT.name != D.name)
									DT.name = D.name
								d_test = 0
						if(d_test)
							new_diseases += D.Copy() //add a copy instead of the beaker disease
							user << "New disease added to the database!"

/obj/machinery/computer/pandemic/proc/upload_vaccine(var/mob/user)
	if(beaker && beaker.reagents)
		if(beaker.reagents.reagent_list.len)
			var/datum/reagent/blood/BL = locate() in beaker.reagents.reagent_list
			if(BL)
				if(BL.data && BL.data["resistances"])
					for(var/resistance in BL.data["resistances"])
						var/v_test = 1
						for(var/res in new_cures)
							if(resistance == res)
								v_test = 0
						if(v_test)
							new_cures[resistance] = resistance
							user << "New vaccine added to the database!"

/obj/machinery/computer/pandemic/proc/delete_virus(virus_to_delete)
	var/pos = text2num(virus_to_delete)
	new_diseases.Cut(pos, pos + 1)



/obj/machinery/computer/pandemic/proc/delete_vaccine(vaccine_to_delete)
	var/pos = text2num(vaccine_to_delete)
	new_cures.Cut(pos, pos + 1)

/obj/machinery/computer/pandemic/on_deconstruction()
	if(beaker)
		beaker.loc = get_turf(src)
	..()	

#undef TAB_ANALYSIS
#undef TAB_EXPERIMENT
#undef TAB_DATABASE
