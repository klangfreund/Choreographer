$(document).ready(function()
{
  // if we got here, JS is obviously enabled
  $("#jsDisabled").remove();
  
  // load the data
  dataController.loadData();
  dataController.buildNavigation();
  
  // navigation and hash
  // ----------------------------------------------------------------
  if (('onhashchange' in document) || ('onhashchange' in window)) {
  // Checking for 'onhashchange' event in 'window' object
  // and in 'document' object
  window.onhashchange = browseController.changeContent; 
  }
  else {
  // no 'onhashchange' event found? the browser doesn't support this event
  // set a timer to call the function after every 500 milliseconds
  window.setInterval("browseController.changeContent()", 500);
  }
  
  // call the function in case there is no hash when the page is loaded
  browseController.changeContent();
  
  // show breadcrumbs only if not viewed in Help Viewer
  if(navigator.userAgent.match(/Help Viewer/))
  {
    $("#breadcrumb").remove();
  }
  else
  {
    var name = $("#breadcrumb").text();
    $("#breadcrumb").html('<a href="#">Choreographer Help</a> &gt; ' + name);
  }
});


/* dataController */

var dataController = {};

(function () { // closure
	var content = {};
	var navigation = {};
	var firstID;

	dataController.loadData = function ()
	{		
		// read in content
		$.ajax({
			url: "content.json",
			dataType: "json",
			async: false,
			success: function (json, status, xhr)
			{
					content = json.content;
					navigation = json.navigation;
			},
			error: function () { console.log("Error loading json file"); }
		});
	};
	
	dataController.buildNavigation = function ()
	{
		var title;
		var navHtml = '<ul>';
		$.each(navigation, function(id, mainItem)
		{
			title = dataController.getTitleForID(id);
			if(title && title !='')
			{
				if(!firstID) firstID = id;
				navHtml += '<li class="nav-main" id="nav-'+ id +'">';
				navHtml += '<a href="#'+ id +'">' + dataController.getTitleForID(id) + '</a>';
				navHtml += '<ul class="nav-sub">';
	
				$.each(mainItem, function(i, subItem)
				{
						var title = dataController.getTitleForID(subItem);
						var content = dataController.getContentForID(subItem);
						if(title && title !='' && content && content != '')
						{					
							navHtml += '<li><a href="#' + subItem + '">';
							navHtml += dataController.getTitleForID(subItem) + '</a></li>';
						}
				});
				
				navHtml += '</ul></li>';
			}
		});
		
		navHtml += '</ul>';
		$('#navigation').html(navHtml);
	};


	dataController.getTitleForID = function (id)
	{
		var item = content[id];
		if(item) return item.title;
	};

	dataController.getContentForID = function (id)
	{
		var item = content[id];
		if(item) 	return item.content;
	};

	dataController.getRelationsForID = function (id)
	{
		var item = content[id];
		if(item) 	return item.related;
	};

	dataController.getFirstID = function ()
	{
		return firstID;
	};

}());



/* browseController */

var browseController = {};

(function () { // closure

	var currentMainID;

	browseController.changeContent = function()
	{
		var hash = location.hash;
		var	id = hash.replace(/^.*#/, '');
		
		if(!id)
		{
			id = currentMainID ? currentMainID : dataController.getFirstID();
		}
		
		var title = dataController.getTitleForID(id);
		var content = dataController.getContentForID(id);
		var related = dataController.getRelationsForID(id);
		var html = '';
						
		// check if title exists
		if(title == null)
		{ 
			id = dataController.getFirstID();
			window.location.href = '#' + id;
		}
	
		// check if content exists
		if(content == null)
		{
			// this is a navigation object

			document.title = "Choreographer Help";
			currentMainID = id;

			// show the navigation and hide the content
			$("#breadcrumb").hide();
			$("#navigationView").show();
			$("#contentView").hide();

			$('.nav-main').removeClass('sel');
			$('#nav-'+ id).addClass('sel');
		}
		else
		{
			// this is a content object

			document.title = "Choreographer Help" + " : " + title;
			$('#contentTitle').html(title);

			// hide the navigation and show the content
			$("#breadcrumb").show();		
			$("#content").html(content);
			$("#navigationView").hide();
			$("#contentView").show();
			
			if(related)
			{
				html += '<hr /><p>RELATED TOPICS</p>';

				$.each(related, function(index, item)
				{
					html += '<p><a href="#'+item+'">'+dataController.getTitleForID(item)+'</a></p>';
				});
			}
			
			$('#related').html(html);

		}
	};

}());