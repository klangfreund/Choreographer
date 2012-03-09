$(document).ready(function()
{
	/* show subnavigation */
	$("li#navigation-main").click(function()
	{
		$('li#navigation-main').removeClass('sel');
		$(this).addClass('sel');
	});
    
    if(navigator.userAgent.match(/Help Viewer/))
    {
         $("#breadcrumb").remove();
    }
    else
                  {
                  var name = $("#breadcrumb").text();
                  $("#breadcrumb").html('<a href="../Choreographer.html">Choreographer Help</a> &gt; ' + name);
                  }
});
