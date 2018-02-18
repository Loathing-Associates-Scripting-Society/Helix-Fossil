
import "scripts/Helix Fossil/Pocket Familiars.ash";

void main()
{
	string [string] form_fields = form_fields();
	buffer page_text;
	if (form_fields["helix_fossil_api_request"] == "true")
	{
		if (form_fields["script_the_fight"] == "true")
		{
			page_text = PocketFamiliarsFight(true);
		}
		else
			return;
	}
	else	
		page_text = visit_url();
	
	//new_text += "v" + __helix_fossil_version;
	boolean within_combat = page_text.contains_text("<input type=submit class=button value='Give Up'>");
	//string base_replacement_string = "<b>Your Team</b>";
	string base_replacement_string = "<td style=\"padding: 5px; border: 1px solid blue;\">";
	
	
	string new_text;
	new_text += "<div style=\"position:absolute;z-index:1000;\">";
	if (within_combat)
	{
		new_text += "<form method=\"post\" action=\"fambattle.php\">";
		new_text += "<input type=\"submit\" class=\"button\" value=\"Script\" alt=\"Helix Fossil v" + __helix_fossil_version + "\" title=\"Helix Fossil v" + __helix_fossil_version + "\">";
		new_text += "<input type=\"hidden\" name=\"helix_fossil_api_request\" value=\"true\">";
		new_text += "<input type=\"hidden\" name=\"script_the_fight\" value=\"true\">";
		new_text += "</form>";
	}
	else
	{
		//Again button:
		//new_text += "<div onclick=\"repeat();\" style=\"border: 2px black solid; font-family: Arial, Helvetica, sans-serif; font-size: 10pt; font-weight: bold; background-color: #FFFFFF; color: #000000; -webkit-appearance: none; -webkit-border-radius: 0;padding:5px;\">Again</div>";
		new_text += "<button style=\"cursor:pointer;\" onmouseup=\"repeat();\" class=\"button\">Again</button>";
	}
	new_text += "</div>";
	page_text.replace_string(base_replacement_string, base_replacement_string + new_text);
	write(page_text);
}