
import "scripts/Helix Fossil/Pocket Familiars.ash";

void main()
{
	string [string] form_fields = form_fields();
	if (form_fields["helix_fossil_api_request"] == "true")
	{
		if (form_fields["script_the_fight"] == "true")
		{
			write(PocketFamiliarsFight(true));
		}
		return;
	}
	//new_text += "v" + __helix_fossil_version;
	buffer page_text = visit_url();
	//string base_replacement_string = "<b>Your Team</b>";
	string base_replacement_string = "<td style=\"padding: 5px; border: 1px solid blue;\">";
	string new_text = "<div style=\"position:absolute;\">";
	new_text += "<form method=\"post\" action=\"fambattle.php\">";
	new_text += "<input type=\"submit\" class=\"button\" value=\"Script\" alt=\"Helix Fossil v" + __helix_fossil_version + "\" title=\"Helix Fossil v" + __helix_fossil_version + "\">";
	new_text += "<input type=\"hidden\" name=\"helix_fossil_api_request\" value=\"true\">";
	new_text += "<input type=\"hidden\" name=\"script_the_fight\" value=\"true\">";
	new_text += "</form></div>";
	page_text.replace_string(base_replacement_string, base_replacement_string + new_text);
	write(page_text);
}