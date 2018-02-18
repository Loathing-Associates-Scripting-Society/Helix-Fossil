import "scripts/Helix Fossil/PocketFamiliarsAutoSelect.ash";

string buildAButtonBear(string button_name, string api_action, string api_arguments)
{
	string new_text;
	new_text += "<form method=\"post\" action=\"famteam.php\" style=\"display:inline;\">";
	new_text += "<input type=\"submit\" class=\"button\" value=\"" + button_name + "\">";
	new_text += "<input type=\"hidden\" name=\"helix_fossil_api_request\" value=\"true\">";
	new_text += "<input type=\"hidden\" name=\"action\" value=\"" + api_action + "\">";
	new_text += "<input type=\"hidden\" name=\"arguments\" value=\"" + api_arguments + "\">";
	new_text += "</form>";
	return new_text;
}

void main()
{
	string [string] form_fields = form_fields();
	buffer page_text;
	if (form_fields["helix_fossil_api_request"] == "true")
	{
		string action = form_fields["action"];
		string arguments = form_fields["arguments"];
		if (action == "build")
		{
			PocketFamiliarsTeamBuildingSettings settings;
			settings.minimum_level_5s_wanted = arguments.to_int();
			PocketFamiliarsBuildTeam(settings);
		}
		page_text = visit_url("famteam.php");
	}
	else
		page_text = visit_url();
	
	string new_text = "<div style=\"bottom:10px;left:10px;position:absolute\">";
	new_text += "Auto-build a team:";
	new_text += "<span style=\"display:inline-block;width:10px;\"> </span>";
	//new_text += "<br>";
	new_text += buildAButtonBear("Average", "build", "1"); //best choice
	//new_text += "<br>";
	new_text += buildAButtonBear("Strongest", "build", "3");
	new_text += buildAButtonBear("Strong", "build", "2");
	new_text += buildAButtonBear("Weak", "build", "0");
	new_text += "</div>";
	string matching_text = "</div></body>";
	page_text.replace_string(matching_text, new_text + matching_text);
	write(page_text);
}