import "scripts/Helix Fossil/Pocket Familiars.ash";

boolean __setting_show_priorities = false;

Record PocketFamiliarsFamTeamStatus
{
	PocketFamiliar [int] familiars;
	PocketFamiliar [int] active_team;
};

PocketFamiliarsFamTeamStatus PocketFamiliarsParseFamTeam(buffer page_text)
{
	PocketFamiliarsFamTeamStatus status;
	if (false)
	{
        string [int][int] familiar_levels_matches = page_text.group_string("<Td class=tiny>Lv. ([0-9]) (.*?)</td>");
        foreach key in familiar_levels_matches
        {
        
            PocketFamiliar f;
      
            f.familiar_name_raw = familiar_levels_matches[key][2];
                  
            f.level = familiar_levels_matches[key][1].to_int();
            f.f = f.familiar_name_raw.to_familiar();
            //print_html(f.f + " (" + f.familiar_name_raw + "): " + f.level);
            
            status.familiars[status.familiars.count()] = f;
        }
	}
	else
	{
        string [int][int] familiar_boxes = page_text.group_string("<div class=\"fambox\"(.*?)</div>");
        foreach key in familiar_boxes
        {
            PocketFamiliar f = PocketFamiliarParseFamiliarFromText(familiar_boxes[key][1]);
         
            status.familiars[status.familiars.count()] = f;
            //print_html(f.to_json());
        }
    }
    
    string left_text = page_text.group_string("<b>Active Team</b>(.*?)<b>Bullpen</b>")[0][1];
    //print_html("left_text = " + left_text.entity_encode());
    string [int][int] slot_matches = page_text.group_string("data-pos=\"(.*?)\">(.*?)</div>");
    foreach key in slot_matches
    {
    	int slot_id = slot_matches[key][1].to_int(); 
    	string entry = slot_matches[key][2];
        PocketFamiliar f = PocketFamiliarParseFamiliarFromText(entry);
        status.active_team[slot_id] = f;
        //print_html(slot_id + ": " + f.f);
    }
    
	return status;
}


Record PocketFamiliarsTeamBuildingSettings
{
	int minimum_level_5s_wanted; //or best
	boolean make_familiars_smart;
	boolean rebuild_team_if_it_is_low_level;
};

float PocketFamiliarsScoreFamiliarForSlot(PocketFamiliar f, int slot_id, boolean prefer_level_fives, boolean already_have_secondary_attack, float average_of_non_five_familiars_so_far, int non_five_familiars_so_far, boolean [string] moves_already_have)
{
	int REPLACEME = 0;
	

    int SLOT_FRONT = 0;
    int SLOT_MIDDLE = 1;
    int SLOT_BACK = 2;
    
	float [string] primary_moves_utility_overall;
    primary_moves_utility_overall["Bite"] = 10; //Deal [power] damage to a random enemy.
    primary_moves_utility_overall["Bonk"] = 0; //Deal [power] damage to the frontmost enemy
    primary_moves_utility_overall["Claw"] = -50; //Deal [power] damage to the frontmost enemy and 1 damage to a random enemy.
    primary_moves_utility_overall["Peck"] = 0; //Deal [power] damage to the frontmost enemy
    primary_moves_utility_overall["Punch"] = -25; //Deal [power] damage to the frontmost enemy and reduce its power by 1.
    primary_moves_utility_overall["Sting"] = -100; //Deal [power] damage to the frontmost enemy and poison it.
	
	float [string] secondary_moves_utility_overall; //in the second or third position
	secondary_moves_utility_overall["Swoop"] = 10; //Avoid all attack damage this turn.
    secondary_moves_utility_overall["Retreat"] = 100; //Move to the back.
    secondary_moves_utility_overall["Tackle"] = 100; //Knock the frontmost enemy to the back.
    secondary_moves_utility_overall["Encourage"] = -5; //Increase the frontmost ally's power by 1
    if (f.special_attributes["Armor"])
	    secondary_moves_utility_overall["Armor Up"] = 10; //Become Armored.
    else
        secondary_moves_utility_overall["Armor Up"] = REPLACEME; //Become Armored.
    
    if (!already_have_secondary_attack)
    {
        secondary_moves_utility_overall["Backstab"] = -150; //Deal 1 damage to the rearmost enemy and poison it.
        secondary_moves_utility_overall["Breathe Fire"] = -100; //Deal 1 damage to all enemies.
        secondary_moves_utility_overall["Howl"] = -100; //Deal 1 damage to all enemies.
        secondary_moves_utility_overall["Laser Beam"] = -150; //Deal 2 damage to a random enemy. Ideal for countering those regenerating familiars.
        secondary_moves_utility_overall["Splash"] = -100; //Deal 1 damage to two random enemies
        secondary_moves_utility_overall["Stinkblast"] = -100; //Deal 1 damage to a random enemy and poison it
    }
    else
    {
        secondary_moves_utility_overall["Backstab"] = -6; //Deal 1 damage to the rearmost enemy and poison it.
        secondary_moves_utility_overall["Breathe Fire"] = -5; //Deal 1 damage to all enemies.
        secondary_moves_utility_overall["Howl"] = -5; //Deal 1 damage to all enemies.
        secondary_moves_utility_overall["Laser Beam"] = -5; //Deal 2 damage to a random enemy
        secondary_moves_utility_overall["Splash"] = -5; //Deal 1 damage to two random enemies
        secondary_moves_utility_overall["Stinkblast"] = -6; //Deal 1 damage to a random enemy and poison it
    }
    if (!moves_already_have["Laser Beam"] && !moves_already_have["Backstab"])
    {
    	secondary_moves_utility_overall["Laser Beam"] += -10; //kill regenerating familiars
        secondary_moves_utility_overall["Backstab"] += -10; //kill regenerating familiars
    }
    boolean have_poison_attack = false;
    foreach s in $strings[Backstab,Sting,Stinkblast]
    {
    	if (moves_already_have[s])
        {
			have_poison_attack = true;
            break;
        }
    }
    if (!have_poison_attack)
    {
    	//regenerating familiars are a nightmare
    	foreach s in $strings[Backstab,Stinkblast]
    		secondary_moves_utility_overall[s] += -50.0;
    }
    secondary_moves_utility_overall["Chill Out"] = -2; //Make a random enemy Tired. Or... doesn't do anything at all?
    secondary_moves_utility_overall["Embarrass"] = -1; //Reduce a random enemy's power by 1
    secondary_moves_utility_overall["Frighten"] = -1; //Reduce the frontmost enemy's power by 1
    secondary_moves_utility_overall["Growl"] = -1; //Reduce 2 random enemies' power by 1.
    secondary_moves_utility_overall["Hug"] = -10; //Heal the frontmost ally by [power"]
    secondary_moves_utility_overall["Lick"] = -4; //Heal all allies for 1
    secondary_moves_utility_overall["Regrow"] = -5 * MAX(0, f.hp - 1); //Heal itself by [power]
    if (slot_id == SLOT_BACK)
    {
    	if (prefer_level_fives)
        {
	    	secondary_moves_utility_overall["ULTIMATE: Spiky Burst"] = -10000;
            secondary_moves_utility_overall["ULTIMATE: Blood Bath"] = -100000;
        }
        else
        {
            secondary_moves_utility_overall["ULTIMATE: Spiky Burst"] = -100;
            secondary_moves_utility_overall["ULTIMATE: Blood Bath"] = -101;
        }
    }
    
    float [string] secondary_moves_utility_always;
    /*foreach move in moves_already_have
    {
    	if (!(secondary_moves_utility_overall contains move))
     		continue;
		//print_html("Already have " + move);
		secondary_moves_utility_always[move] += 25.0; //we already have it
    }*/
    
    //float [int][string] moves_priority;
    /*moves_priority[1]["Retreat"] = 100;
    moves_priority[2]["Retreat"] = 100;
    for i from 0 to 2
    {
    	moves_priority["Armor Up"] = 10;
        moves_priority["Bite"] = 1;
        moves_priority["Growl"] = 1;
        moves_priority["Encourage"] = 1;
        moves_priority["Tackle"] = 100;
    }
    foreach s in $strings[Howl,Breathe Fire,Laser Beam,Splash]
        moves_priority[s] = -100;*/
	
	float priority = 0.0;
	
    priority += f.f.to_int().to_float() / 10000.0; //tie breaker
    
    foreach move in f.moves
    {
        //priority += moves_priority_affection[move];
        if (slot_id == SLOT_FRONT)
        {
        	if (f.level < 5)
	        	priority += -secondary_moves_utility_overall[move] * 0.1;
            priority += primary_moves_utility_overall[move] * 0.1;
        }
        else
            priority += secondary_moves_utility_overall[move];
        priority += secondary_moves_utility_always[move];
        if (slot_id == SLOT_MIDDLE)
        	priority += primary_moves_utility_overall[move] * -0.1; //kinda
        
    }
        
    //attack + hp is not linearly correlated to level; some familiars, like the software bug, have maxed out stats at level four
    if (prefer_level_fives)
	    priority += -10.0 * (f.attack + f.hp);
    else
        priority += -1.0 * (f.attack + f.hp);
    if (slot_id == SLOT_FRONT)
    {
    	priority += -2.5 * f.attack;
        priority += -2.0 * f.hp;
    }
    else
    {
        priority += -1.0 * f.attack;
        priority += -2.0 * f.hp;
    }
    if (abs(f.attack - f.hp) >= 4 && f.level >= 5) //avoid familiars with one strength and five hearts, but only if there's no more exp to gain
    	priority += 10.0;
    //priority += 2.0 * abs(f.attack - f.hp); //prefer attack/hp to be close to one another. In other words, the pet cheezling - which is one attack and five HP - is no? Unless it should be because you're casting attack up... who knows?
    
    if (!prefer_level_fives && f.level != 5)
    {
    	//Try to average familiars so we're around level three.
    	//average_of_non_five_familiars_so_far
        float average_after_adding_familiar = (average_of_non_five_familiars_so_far * non_five_familiars_so_far + f.level) / to_float(non_five_familiars_so_far + 1);
        //print_html(average_of_non_five_familiars_so_far + " vs " + average_after_adding_familiar);
        float increase_over_three = average_after_adding_familiar - 3.0;
        //print_html(f.f + ": " + f.level + ": " + increase_over_three);
        if (increase_over_three > 0.0 && non_five_familiars_so_far > 0)
	        priority += 100.0 * increase_over_three;
    }
    if (f.level == 5)
    {
        if (!prefer_level_fives)
            priority += 2000.0;
        else
        	priority += -10.0;
    }
    else
    {
    	//if ($familiars[space jellyfish,killer bee] contains f.f)
     		//priority += -1000.0; //we want that ultimate   
    }
    if (f.special_attributes["Smart"] && f.level < 5)
    {
    	if (prefer_level_fives)
	        priority -= 5.0;
        else
        	priority -= 20.0;
    }
    
    if (f.level == 1 && $item[piracetam].item_amount() > 0 && !f.special_attributes["Smart"])
    {
    	//Prefer level-one familiars for piracetam. It's less efficient on higher-level familiars.
    	priority -= 10.0;
    }
    if (slot_id == SLOT_FRONT)
    {
        if (f.special_attributes["Regenerating"])
            priority -= 10.0;
        if (f.special_attributes["Spiked"])
            priority -= 5.0;
        if (f.special_attributes["Armor"])
            priority -= 2.0;
    }
    else
    {
        if (f.special_attributes["Regenerating"])
            priority -= 10.0;
        if (f.special_attributes["Spiked"])
            priority -= 1.0;
        if (f.special_attributes["Armor"])
            priority -= 0.5;
    }
    //print_html(f.f + ": " + slot_id + " - " + priority);
	return priority;
}

Record PocketFamiliarsTeamResult
{
    familiar [int] chosen_team;
    familiar chosen_spiky_burst_familiar;
};

PocketFamiliarsTeamResult PocketFamiliarsCalculateTeam(PocketFamiliarsTeamBuildingSettings settings, PocketFamiliarsFamTeamStatus status, PocketFamiliar [familiar] familiars_have)
{
    familiar [int] chosen_team;
    
    PocketFamiliar [int] familiars = status.familiars;
    
    
    familiar [int] spiky_burst_familiars;
    spiky_burst_familiars.listAppend(to_familiar("Slotter")); //has blood bath, which is amusingly overpowered
    spiky_burst_familiars.listAppend($familiar[space jellyfish]); //has Backstab, which is an attack we can alternate with
    spiky_burst_familiars.listAppend($familiar[killer bee]); //has growl, which can weaken enemy attack
    spiky_burst_familiars.listAppend($familiar[Mutant Cactus Bud]); //regenerates, but doesn't have a good secondary
    spiky_burst_familiars.listAppend($familiar[bark scorpion]); //similar to bee, but very little HP
    spiky_burst_familiars.listAppend($familiar[Dramatic Hedgehog]); //out of standard
    
    
    //Pick a good team that... wait
    //Pick a team.
    int level_five_or_equivalent_familiars_have = 0;
    /*if (settings.minimum_level_5s_wanted > 0)
    {
        foreach f in $familiars[space jellyfish,killer bee]
        {
            if (!(familiars_have contains f)) continue;
            chosen_team[2] = f;
            level_five_or_equivalent_familiars_have += 1;
            break;
        }
        //FIXME if chosen_team[2] is non, pick a five-level familiar. though really, if you don't have a killer bee...
    }*/
    familiar chosen_spiky_burst_familiar;
    foreach key, f in spiky_burst_familiars
    {
        if (!(familiars_have contains f)) continue;
        if (f == $familiar[none]) continue;
        if (chosen_spiky_burst_familiar == $familiar[none])
            chosen_spiky_burst_familiar = f;
        if (familiars_have[f].level >= 5 && settings.minimum_level_5s_wanted == 0) //have it
            break;
        chosen_team[2] = f;
        if (familiars_have[f].level >= 5)
	        level_five_or_equivalent_familiars_have += 1;
        break;
    }
    //abort("chosen_spiky_burst_familiar = " + chosen_spiky_burst_familiar);
    
    
    if (true)
    {
        //New method:
        //Pick familiars in reverse order. Or maybe back, front, middle:
        
        int [int] ordering;
        ordering.listAppend(2);
        ordering.listAppend(0);
        ordering.listAppend(1);
        
        foreach key_discard_1, slot_id in ordering
        {
            if (chosen_team contains slot_id) continue;
            
            boolean already_have_secondary_attack = false;
            int score_familiar_as_slot = slot_id;
            boolean [string] moves_already_have;
            for i from 0 to 2
            {
                if (!(chosen_team contains i)) continue;
                foreach s in familiars_have[chosen_team[i]].moves
                    moves_already_have[s] = true;
            }
            if (slot_id == 1)
            {
                //If slot 2 already has a secondary damaging skill, score as slot zero, since we can always alternate. Unless that one dies, I suppose.
                foreach s in $strings[Backstab,Breathe Fire,Howl,Laser Beam,Splash,Stinkblast]
                {
                    //if (familiars_have[chosen_team[2]].moves[s])
                    if (moves_already_have[s])
                    {
                        already_have_secondary_attack = true;
                        break;
                    }
                }
            }
            float average_of_non_five_familiars_so_far = 0.0;
            int non_five_familiar_count = 0;
            foreach i, f in chosen_team
            {
                int level = familiars_have[f].level;
                if (level == 5) continue;
                average_of_non_five_familiars_so_far += level;
                non_five_familiar_count += 1;
            }
            if (non_five_familiar_count > 0)
                average_of_non_five_familiars_so_far /= to_float(non_five_familiar_count); 
            float [familiar] priorities;
            foreach key, f in familiars
            {
                priorities[f.f] = PocketFamiliarsScoreFamiliarForSlot(f, score_familiar_as_slot, level_five_or_equivalent_familiars_have < settings.minimum_level_5s_wanted, already_have_secondary_attack, average_of_non_five_familiars_so_far, non_five_familiar_count, moves_already_have);
            }
            sort familiars by priorities[value.f];
            
            if (__setting_show_priorities)
            {
                string [int] output;
                foreach key, f in familiars
                {
                    output.listAppend(f.f + ": " + priorities[f.f]);
                }
                print_html("Slot " + slot_id + ": " + output.listJoinComponents(", ", ""));
                print_html("");
            }
            
            foreach key, f in familiars
            {
                //if (f.level >= 5 && level_five_or_equivalent_familiars_have >= settings.minimum_level_5s_wanted)
                    //continue;
                //print_html("Examining " + f.f + " for slot " + slot_id);
                
                boolean no = false;
                for i from 0 to 2
                {
                    if (chosen_team[i] == f.f)
                    {
                        no = true;
                    }
                }
                if (no)
                    continue;
                //print_html("<font color=red>Picked " + f.f + " for slot " + slot_id + "</font>");
                chosen_team[slot_id] = f.f;
                if (f.level >= 5)
                    level_five_or_equivalent_familiars_have += 1;
                break;
            }
        }
    }
    
    
    PocketFamiliarsTeamResult out;
    out.chosen_team = chosen_team;
    out.chosen_spiky_burst_familiar = chosen_spiky_burst_familiar;
    return out;
}

void PocketFamiliarsBuildTeam(PocketFamiliarsTeamBuildingSettings settings)
{
    
    PocketFamiliarsFamTeamStatus status = PocketFamiliarsParseFamTeam(visit_url("famteam.php"));
    PocketFamiliar [familiar] familiars_have;
    foreach key, f in status.familiars
    {
        familiars_have[f.f] = f;
    }
    PocketFamiliarsTeamResult team = PocketFamiliarsCalculateTeam(settings, status, familiars_have);
	
	if (settings.rebuild_team_if_it_is_low_level)
	{
		//Basically, include a jellyfish if we're a team of low-levels:
		float average_level = 0.0;
        foreach key, f in team.chosen_team
        {
        	average_level += familiars_have[f].level;
        }
        if (team.chosen_team.count() > 0)
        	average_level /= to_float(team.chosen_team.count());
        float cutoff = 2.5;
        if (average_level < cutoff) //2.5?
        {
        	settings.minimum_level_5s_wanted += 1;
            team = PocketFamiliarsCalculateTeam(settings, status, familiars_have);
        }
	}
	
	//famteam.php?slot=1&fam=171&action=slot
	
	print_html("Chosen team: " + team.chosen_team.listJoinComponents(", ", "and") + ".");
	//abort("");
	foreach key, f in team.chosen_team
	{
		int slot_id = key + 1;
        if (status.active_team[slot_id].f != f)
        {
            print_html("Switching slot " + slot_id + " to " + f);
            visit_url("famteam.php?slot=" + slot_id + "&fam=" + f.to_int() + "&action=slot");
        }
	}
	if ($item[piracetam].item_amount() > 0 && settings.make_familiars_smart)
	{
		familiar [int] chosen_team_copy;
    	foreach key, f in team.chosen_team
        	chosen_team_copy.listAppend(f);
        sort chosen_team_copy by familiars_have[value].level;
        foreach key, f in chosen_team_copy
        {
        	//Don't make the space jellyfish (or killer bee, if we don't have the fish) smart, because we'll be bringing them along for quite a while.
        	if (f == team.chosen_spiky_burst_familiar) continue;
            if ($item[piracetam].item_amount() > 0 && !familiars_have[f].special_attributes["Smart"] && familiars_have[f].level < 5 && settings.make_familiars_smart)
            {
                print("Feeding piracetam to " + f);
                visit_url("famteam.php?iid=9751&fam=" + f.to_int() + "&action=feed");
                cli_execute("refresh inventory");
            }
        } 
	}
	
}


void main(int minimum_level_fives_wanted)
{
	PocketFamiliarsTeamBuildingSettings settings;
	settings.minimum_level_5s_wanted = minimum_level_fives_wanted;
	PocketFamiliarsBuildTeam(settings);
}
