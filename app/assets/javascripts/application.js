// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery
//= require jquery_ujs
//= require bootstrap
//= require_tree ../../../vendor/assets/javascripts
//= require cocoon
//= require google-code-prettify
//= require jquery.observe_field
//= require gmaps4rails/gmaps4rails.base
//= require gmaps4rails/gmaps4rails.googlemaps
//= require jquery.dataTables
//= require_tree .

function color_legend() 
{
	return '<table>' +
	'<tr class="fail"><td>0-20%</td><td>Poor Performance</td></tr>' +
	'<tr class="warning"><td>20-60%</td><td>Below Average Performance</td></tr>' +
	'<tr class="pass"><td>60-80%</td><td>Above Average Performance </td></tr>' +
	'<tr class="exceptional"><td>80-100%</td><td>Exceptional Performance</td></tr>' +
	'</table>';
}

$('#time_filter_start_time_2i').live('change', function() 
{
	$(this).parents('form:first').submit();
});

$('#time_filter_start_time_1i').live('change', function() 
{
	$(this).parents('form:first').submit();
});

$('#time_filter_designation').live('change', function() 
{
	$(this).parents('form:first').submit();
});

$("*[data-spinner]").live('ajax:beforeSend', function(e){
	$($(this).data('spinner')).show();
});

$("*[data-spinner]").live('ajax:complete', function(){
	$($(this).data('spinner')).hide();
});

function apply_compliance_datatable()
{
	add_details_field_datatable('compliance_dtable');
	var oTable = $("table#compliance_dtable").dataTable
	( {
		"sDom": "<'row'<'span6'l><'span6'f>r>t<'row'<'span6'i><'span6'p>>",
		"sPaginationType": "bootstrap",
		"oLanguage": {"sLengthMenu": "_MENU_ records per page"},
		"aoColumnDefs": [
		{ "bSortable": false, "aTargets": [ 0 ] },
		{ "bVisible": false, "aTargets": [ 7,8,9,10,11 ] },
		{ "iDataSort": 19, "aTargets": [ 2 ] },
		{ "iDataSort": 20, "aTargets": [ 3 ] },
		{ "iDataSort": 21, "aTargets": [ 4 ] },
		],
		"aaSorting": [[ 2, "asc" ]],
		"bInfo": true,
		//"bLengthChange": false,
		//"bPaginate": false,
		"fnDrawCallback": function() {
			$('.dataTables_paginate').css("display", "block");  
			$('.dataTables_length').css("display", "block");
			$('.dataTables_filter').css("display", "block");                        
		}
		
	} );
	register_details_field_click_event('compliance_dtable',oTable);
}

function indicator_script()
{

	$('a.dropdown-toggle').dropdown(); //little fix to let dropdowns work with single clicks

	preloading_functions[current_visualization_type]();
	loading_functions[current_visualization_type][current_visualization]();

	$(".activity-toggle").click(function () 
	{
		//Change indicator button text
		$("#indicator_selector").html(gon.indicator_names[$(this).data("activity")][0]+" <span class=\"caret\"></span>");
		
		$("#indicator_type").html(gon.indicator_names[$(this).data("activity")][0]);

		//write html for indicators button dropdown
		var sOut = "<li class=\"active\"><a href=\"#\" data-indicator=\""+gon.indicator_hooks[$(this).data("activity")][0]+"\" data-indicator_name=\""+gon.indicator_names[$(this).data("activity")][0]+"\" id=\""+gon.indicator_hooks[$(this).data("activity")][0]+"\" data-toggle=\"tab\" class=\"indicator-toggle\">"+ gon.indicator_names[$(this).data("activity")][0]+"</a></li>";
		
		for (var i = 1; i < gon.indicator_hooks[$(this).data("activity")].length; i++) 
		{
			sOut += "<li><a href=\"#\" data-indicator=\""+gon.indicator_hooks[$(this).data("activity")][i]+"\" data-indicator_name=\""+gon.indicator_names[$(this).data("activity")][i]+"\" id=\""+gon.indicator_hooks[$(this).data("activity")][i]+"\" data-toggle=\"tab\" class=\"indicator-toggle\">"+ gon.indicator_names[$(this).data("activity")][i]+"</a></li>";
		}
		$("#indicator_set").html("<li class=\"nav-header\">	Look at	</li>"+sOut);
		
		//Run visualization code for newly selected indicator
		current_visualization = gon.indicator_hooks[$(this).data("activity")][0];
		loading_functions[current_visualization_type][current_visualization]();
		
		//Change self text of button
		$("#activity_type").html($(this).data("activity_name"));
		$("#activity_selector").html($(this).html()+" <span class=\"caret\"></span>");
	});

$(document).on("click", ".indicator-toggle", function()
{ 
	current_visualization = $(this).data("indicator");
	loading_functions[current_visualization_type][current_visualization]();
	$("#indicator_type").html($(this).data("indicator_name"));
	$("#indicator_selector").html($(this).html()+" <span class=\"caret\"></span>");
});

$(".visualization-toggle").click(function () 
{
	current_visualization_type = $(this).data("visualization");
	preloading_functions[current_visualization_type]();
	loading_functions[current_visualization_type][current_visualization]();
	$("#visualization_type").html($(this).data("visualization"));
	$("#visualization_selector").html($(this).html()+" <span class=\"caret\"></span>");
});

}

function apply_indicators_datatable()
{
	var oTable = $("table#indicators_dtable").dataTable
	( {
		"oTableTools": {
			"sSwfPath": gon.flash_path,
			"aButtons": [
			"copy",
			"csv",
			"xls"
			]
		},
		"sDom": 'T<"clear">lfrtip',
		"sScrollX": "100%",
		"bScrollCollapse": true,
		"sScrollY": 450,
		"sPaginationType": "bootstrap",
		"oLanguage": {"sLengthMenu": "_MENU_ records per page"},
		"aaSorting": [[ 1, "desc" ]],
		"bInfo": true,
		"bLengthChange": false,
		"bPaginate": false,
		"fnDrawCallback": function() 
		{
			$('.dataTables_filter').css("display", "block");                        
		}
		
	} );
	new FixedColumns( oTable, {
		"iLeftColumns": 1,
		"iLeftWidth": 150
	} );
}

$(document).ready(function() {
	$('a.dropdown-toggle').dropdown(); //little fix to let dropdowns work with single clicks
	$("#loading").hide();
	$("#stuff").show("fast");
	$('.calendar_field').datepicker({dateFormat: "dd-mm-yy"});
});