///////////////////////
// Javascript for fieldnotes DB
// Some code taken from:
//    http://www.shawnolson.net/scripts/public_smo_scripts.js
//

var activity_counter = 0;
var kid_counter      = 0;
var file_counter     = 0;

function checkForm(frm) {
  for(i = 0; i < frm.length; ++i) {
    box = frm.elements[i];
    if(! box.value && box.name != 'parent' && box.name != 'submit' && box.name != 'file' ) {
      alert('You haven\'t filled in ' + box.name + '!');
      return false;
    }
  }

  return true;
}

function checkAllBoxes(frm) {
  for(i = 0; i < frm.length; ++i) {
    if (frm[i].type == 'checkbox') {
       frm[i].checked = true;
       toggleRow(frm[i]);
    }
  }
}

function uncheckAllBoxes(frm) {
  for(i = 0; i < frm.length; ++i) {
    if (frm[i].type == 'checkbox') {
       frm[i].checked = false;
       toggleRow(frm[i]);
    }
  }
}

function toggleRow(elem) {
  var row = elem.parentNode.parentNode;

  if(elem.checked) {
    row.parentNode.className = "hilite";
  } else {
    row.parentNode.className = "";
  }


  return true;
}

function followLink(event, elem, href) {
  chkbox       = elem.childNodes[0];
  parentLeft   = findPosX(elem);
  parentTop    = findPosY(elem);
  parentRight  = parentLeft + elem.width;
  parentBottom = parentTop + elem.height;

  if (chkbox) {
    childLeft   = findPosX(chkbox);
    childTop    = findPosY(chkbox);
    childRight  = childLeft + chkbox.offsetWidth;
    childBottom = childTop  + chkbox.offsetHeight;

    posX = event.clientX;
    posY = event.clientY;

    if((posX < childLeft || posX > childRight || posY <
        childTop || posY > childBottom)) {

	document.location.href = href;
    }
  }
}

function findPosX(obj) {
  var curleft = 0;
  if(obj.offsetParent) {
    while (obj.offsetParent) {
      curleft += obj.offsetLeft
      obj = obj.offsetParent;
    }
  } else if(obj.x) {
    curleft += obj.x;
  }

  return curleft;
}

function findPosY(obj) {
 var curtop = 0;
 if(obj.offsetParent) {
   while(obj.offsetParent) {
     curtop += obj.offsetTop
     obj = obj.offsetParent;
   }
  } else if(obj.y) {
    curtop += obj.y;
  }

  return curtop;
}

function moreFields(fieldName, selectedField, aTime, aTask) {
	var boxName = '';
	var counter =  0;

	if(fieldName == 'activity') {
		boxName = 'box-activity';
		insName = 'activity-insert';
		activity_counter++;
		counter =  activity_counter;
	} else if(fieldName == 'kid') {
		boxName = 'box-kid';
		insName = 'kid-insert';
		kid_counter++;
		counter =  kid_counter;
	} else if(fieldName == 'file' ) {
		boxName = 'box-file';
		insName = 'file-insert';
		file_counter++;
		counter = file_counter;
	}

	// Duplicate the div that contains
	//  all the form elements.
	var newFields = document.getElementById(boxName).cloneNode(true);

	// If we have a good duplication, we continue
	if( newFields ) {

		// We will probably need to assign 
		//  the div a new id name
		newFields.id = '';
		newFields.style.display = 'block';

		// These are the children of the div
		//  which means the delete button,
		//  the menu and possibly other form
		//  elements for this duplicated object.
		var newField = newFields.childNodes;

		// Iterate through each child object of
		//  the div of form elements
		for (var i=0;i<newField.length;i++) {
			// Get the name of the element
			var theName = newField[i].name;

			// If this is an activity menu, then we 
			//   we may need to set the default taskcard
			//   and tasktime values
			if(fieldName == 'activity' && newField[i].name == 'taskcard') {
				if(aTask >= 1) {
					newField[i].checked = true;
				} else {
					newField[i].checked = false;
				}
			}

                        if(fieldName == 'activity' && newField[i].name == 'minutes') {
                                newField[i].value = aTime;
                        }

			// If the element exists, then give it
			//  a unique name by appending the number
			//  of its place in the order
			if (theName) {
				newField[i].name = theName + counter;
			}


			// Check if this child form element is
			//  the pull down menu that needs to have
			//  a default value selected.
			if(theName == fieldName) {
				// We have found the menu object.
				// Now grab the menu items.
				var menuItems = newField[i].childNodes;

				// Go through each menu item and, if it
				//  is the selected value, then set its
				//  selected value to 'true.'
				for(var mi = 0; mi < menuItems.length; mi++) {
					if(menuItems[mi].value == selectedField) {
						menuItems[mi].selected = true;
					}
				}
			}
		}

		var insertHere = document.getElementById(insName);
		insertHere.parentNode.insertBefore(newFields,insertHere);

		var counterField = document.getElementById(fieldName + '-counter');
		if(counterField) {
			counterField.value = counter;
		}
	}
}

