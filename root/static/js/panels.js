function load_panel_data($panel, panel_class, display_function, refresh)
	{
	$panel.find(".panel-body").html(loading_icon());
	api_json(
		{
		type:          "GET",
		url:           panel_urls[panel_class],
		what:          "Load " + panel_class,
		success_toast: false,
		success:       function(data)
			{
			display_function(data, $panel);
			if (refresh)
				setTimeout(function() { load_panel_data($panel, panel_class, display_function); }, 60000);
			}
		});
	}
function init_panel(panel_class, panel_function, refresh)
	{
	var $panel = $(".hive-panel-" + panel_class);

	if (refresh !== false)
		refresh = true;

	if (!$panel.length || !panel_function || !(panel_class in panel_urls))
		return;

	load_panel_data($panel, panel_class, panel_function, refresh);
	}

function display_temp_data(data, $temp_panel)
	{
	var temp, i, html = "";

	for (i = 0; i < data.temps.length; i++)
		{
		temp = data.temps[i];
		html += temp.display_name + ": " + temp.value.toFixed(1) + "&deg;F<br />";
		}
	$temp_panel.find(".panel-body").html(html);
	}

$(function() { init_panel("temp", display_temp_data); });