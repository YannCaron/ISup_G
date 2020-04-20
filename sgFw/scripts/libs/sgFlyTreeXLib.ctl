/*
Version 1.2
Created 15 September 2005
By Andrew Burkimsher

History:
15/09/2005 Version 1.0 created
22/08/2006 Version 1.1 created:
	Added Functions:
		sgTree_SetAllListItemsStateTo(shape checklist, int state)
		sgTree_UntickAllCheckListItems(shape checklist)
		sgTree_TickAllCheckListItems(shape checklist)
28/09/2006 Version 1.2 created:
	Added Function:
		sgTree_SetUpTreeAsColoredPickListTable(shape Tree)
*/

const int TREE_STATE_RADIO_SELECTED = 4;
const int TREE_STATE_RADIO_UNSELECTED = 5;
const int TREE_STATE_TICKED = 2;
const int TREE_STATE_UNTICKED = 1;
const int TREE_STATE_UNTICKABLE = 6;

dyn_string EMPTY_DYN_STRING;


//############################### Checked Items In Checklist ###############################
dyn_string sgTree_CheckedItemsInCheckList(shape CheckList)
{
//returns the items that are checked in a flytree set up as a check list
dyn_string result;
idispatch curr_node;
for (int i = 0; i<= (CheckList.Items.Count - 1); i++)
	{
	curr_node = CheckList.GetNodeAtRow(i);
	if (curr_node.StateIndex == TREE_STATE_TICKED)
		{
		dynAppend(result, curr_node.Text);
		}
	}
return result;
}

//############################### Selected Item in Radio List ###############################
string sgTree_SelectedItemInRadioButtonList(shape RadioList)
{
//returns the single item that is selected in a flytree set up as a radio button list
//though under STRANGE circumstances if more than one item is selected (should be impossible!) it returns the last selected item
//if no item is selected it returns an empty string
string result = "";
idispatch curr_node;
for (int i = 0; i<= RadioList.Items.Count-1; i++)
	{
	curr_node = RadioList.GetNodeAtRow(i);
	if (curr_node.StateIndex == TREE_STATE_RADIO_SELECTED)
		{
		result = curr_node.Text;
		}
	}
return result;
}

string sgTree_SelectedNodeText(shape FlyTreeControl)
{
idispatch curr_node;
curr_node = FlyTreeControl.ExtractNode(FlyTreeControl.Selected);
return curr_node.Text;
}

string sgTree_SelectedNodeData(shape FlyTreeControl)
{
idispatch curr_node;
curr_node = FlyTreeControl.ExtractNode(FlyTreeControl.Selected);
return curr_node.Data;
}

string sgTree_SelectedNodePath(shape FlyTreeControl)
{
idispatch curr_node;
curr_node = FlyTreeControl.ExtractNode(FlyTreeControl.Selected);
return curr_node.Path;
}

bool sgTree_SelectedNodeHasChildren(shape FlyTreeControl)
{
idispatch curr_node;
curr_node = FlyTreeControl.ExtractNode;
return curr_node.HasChildren;
}



	//Sub-Functions for InsertAsTreeNodes
	int ShallowestDifferent(dyn_string dyn1, dyn_string dyn2)
	//finds the smallest index for which the 2 dyn_strings have different values
	{
	int shorter, result;
	//result = 0;
	if (dynlen(dyn1) < dynlen(dyn2))
		{
		shorter = dynlen(dyn1);
		}
	else
		{
		shorter = dynlen(dyn2);
		}

	for (int i = 1; i <= shorter; i++)
		{
		if (dyn1[i] != dyn2[i])
			{
			return i;//for shallowest different, not deepest same
			}
		}
	}

	dyn_anytype dynSubrange(dyn_anytype array, int start, int finish)
	{
	dyn_anytype result;
	if (finish <= dynlen(array))
		{
		for (int i = start; i <= finish; i++)
			{
			dynAppend(result, array[i]);
			}
		}
	return result;
	}

	string ConcatDynStringWithChar(dyn_string list, char separator)
	{
	string curr_result = "";
	int list_length = dynlen(list);
	if (list_length == 1)
		{
		curr_result = list[1];
		}
	if (list_length > 1)
		{
		for (int i = 1; i < list_length;i++)
			{
			curr_result = curr_result + list[i] + separator;
			}
		curr_result = curr_result + list[list_length];
		}
	return curr_result;
	}


//############################### Insert a dyn_string as Tree Nodes ###############################
dyn_int sgTree_InsertDynAsNodes(dyn_string leaves, shape Tree)
//this takes a dyn string of LEAVES
//(a leaf (plural: leaves) is a node in a tree that has NO children (sub-nodes) )
//in the format ((x.)^n).leaf eg: 'x.y.z.leaf' or even just 'leaf'
//and displays it in the tree, with the non-leaf parts of the string as branches.
//the parents of the leaf are created automatically if they do not already exist

{
//local variables
dyn_dyn_string leaf_paths;
dyn_int intermediates, result; //intermediate nodes (branches)
int num_leaves, curr_shallowest_different;
idispatch curr_parent_node, curr_parent, this_node;
string curr_dp_name = "";
anytype curr_parent_data;

Tree.Items.Clear;//clear existing tree

dynSortAsc(leaves); //the algorithm only works on a sorted list of leaves - i hope this isn't too much of a performance hit...
										//i suppose this could be disabled if you knew the list was sorted if performance was necessary
num_leaves = dynlen(leaves);
//parse the leaf names into their component bits
for (int i = 1; i <= num_leaves; i++)
	{
	leaf_paths[i] = strsplit(leaves[i], ".");
	}

//insert the leaves into the table, creating the branches on the way
for (int j = 1; j <= num_leaves; j++)
	{
	//find if this is still a sub-node of anything
	if (j != 1)
		{
		curr_shallowest_different = ShallowestDifferent(leaf_paths[j - 1], leaf_paths[j]);
		}
	else
		{
		curr_shallowest_different = 1;
		}
	//insert the nodes into the table
	for (int k = curr_shallowest_different; k <= dynlen(leaf_paths[j]); k++)
		{
		if (k == 1)
			{
			intermediates[1] = Tree.Items.Add(leaf_paths[j][1]);
			this_node = Tree.ExtractNode(intermediates[1]);
			this_node.Data = leaf_paths[j][1];
			}
		else
			{
			curr_parent_node = Tree.ExtractNode(intermediates[k-1]);
			intermediates[k] = curr_parent_node.Add(leaf_paths[j][k]);
			this_node = Tree.ExtractNode(intermediates[k]);
			this_node.Data = ConcatDynStringWithChar(dynSubrange(leaf_paths[j], 1, k), "."); //** makes this_node.Data a string representing the node's path
			}//end if
		if (k == dynlen(leaf_paths[j]))
			{
			result[j] = intermediates[k];
			}//end if
		}//end for
	}//end for
}//end insert dyn as nodes


//############################### Fill List ###############################
void sgTree_FillList(shape list, dyn_string nodes, int default_state_index)
//creates all the items in a 1-dimensional list
//and sets each item to have a 'default state index' - for the different kinds of list (checked/unchecked/radio_unselected/radio_selected)
{
int curr_node_id;
idispatch curr_node;

list.Items.Clear;
for (int i = 1; i<= dynlen(nodes); i++)
	{
	curr_node_id = list.Items.Add(nodes[i]);
	curr_node = list.ExtractNode(curr_node_id);
	curr_node.StateIndex = default_state_index;
	curr_node.Data = nodes[i];
	}
}

//############################### Radio Button Click ###############################
//a call to this must be made from the OnClick event of every tree you wish to set up as a radio list
void sgTree_RadioBtnClick(shape RadioList)
{
idispatch curr_node;
//de-select all items in the list
for (int i = 1; i <= RadioList.Items.Count; i++)
	{
	curr_node = RadioList.GetNodeAtRow(i-1);
//DebugN(curr_node.Text);
	curr_node.StateIndex = TREE_STATE_RADIO_UNSELECTED;
	}
//display selected for the currently selected node
curr_node = RadioList.ExtractNode(RadioList.Selected);
curr_node.StateIndex = TREE_STATE_RADIO_SELECTED;
}

//############################### CheckList Mouse Down ###############################
void sgTree_CheckListMouseDown(shape CheckList, float xCoord)
{
//A call to this must be made from the MouseDown event of every tree you wish to set up as a check list
//this is so you can click on the name of the checked item and have it check/uncheck the box
//otherwise only the actual checkbox would be clickable
const int ACTIVE_AREA_CUTOFF = 41; //coord 41 is the cut-off between the checkbox and the text areas. (relative to activeX control, not panel, so can be absolute)
idispatch curr_node;
//DebugN(xCoord);
//if they click on the name, not the checkbox, do the same as if they had clicked the box (toggle the checkbox)
if (xCoord > ACTIVE_AREA_CUTOFF)
	{
	curr_node = CheckList.ExtractNode(CheckList.Selected);
	int curr_state_index = curr_node.StateIndex;
	
	if (curr_state_index == TREE_STATE_UNTICKED)
		{
		curr_node.StateIndex = TREE_STATE_TICKED;
		}
	else if (curr_state_index == TREE_STATE_TICKED)
		{
		curr_node.StateIndex = TREE_STATE_UNTICKED;
		}
	}
}


//############################### Get Item List ###############################
dyn_string sgTree_GetItemList(shape list)
{
dyn_string result;
idispatch curr_node;
string curr_node_text;
for (int i = 0; i<= list.Items.Count-1;i++)
	{
	curr_node = list.GetNodeAtRow(i);
	curr_node_text = curr_node.Text;
	dynAppend(result, curr_node_text);
	}
return result;
}



//############################### Tick Named Checklist Items ###############################
void sgTree_TickNamedCheckListItems(shape checklist, dyn_string items)
{
sgTree_SetNamedItemsTo(checklist, items, TREE_STATE_TICKED);
}


//############################### Set Named Items To ###############################
void sgTree_SetNamedItemsTo(shape list, dyn_string items, int state)
{
//checks the nodes in checklist given in items
idispatch curr_node;
int ref;
dyn_string ItemList = sgTree_GetItemList(list);

DebugTN("sgFlyTreeXLib; sgTree_SetNamedItemsTo; state:" + state + " items:" +items);

for (int i = 1; i<= dynlen(items); i++)
	{
	ref = dynContains(ItemList, items[i]);
	if (ref != 0)
		{
          	curr_node = list.Items.Item(ref-1);
		//curr_node.StateIndex = state;
		}
	}
}



//############################### Tick All Checklist Items ###############################
void sgTree_TickAllCheckListItems(shape checklist)
{
sgTree_SetAllListItemsStateTo(checklist, TREE_STATE_TICKED);
}

//############################### Untick All Checklist Items ###############################
void sgTree_UntickAllCheckListItems(shape checklist)
{
sgTree_SetAllListItemsStateTo(checklist, TREE_STATE_UNTICKED);
}

//############################### Set the state of all items in a list to a value ###############################
void sgTree_SetAllListItemsStateTo(shape checklist, int state)
{
idispatch curr_node;
for (int i = 0; i < checklist.Items.Count; i++)
	{
	curr_node = checklist.Items.Item(i);
	curr_node.StateIndex = state;
	}
}


//############################### Selects an item in a radio list ###############################
void sgTree_SelectItemInRadioList(shape radiolist, string item)
{
//traverses radio list, when finds correct item, it selects it.
//if the item is not found , no item is selected!
string curr_node_text;
idispatch curr_node;
dyn_string ItemList = sgTree_GetItemList(radiolist);

for (int i = 1; i<=dynlen(ItemList); i++)
	{
	curr_node = radiolist.GetNodeAtRow(i-1);
	if (ItemList[i] == item)
		{
		curr_node.StateIndex = TREE_STATE_RADIO_SELECTED;
		}
	else
		{
		curr_node.StateIndex = TREE_STATE_RADIO_UNSELECTED;
		}
	}
}

//############################### Selected Node IDs in Tree ###############################
dyn_int sgTree_SelectedNodeIDsInFlyTree(shape Tree)
{
//this traverses the tree, and returns a list of NodeIDs that are selected
//this is so that multiple selections can be handled
dyn_int result;
int sel_num = 0;
int curr_node_id = 0;

if (Tree.Items.GetFirstSelectedNode != 0)
	{
	sel_num++;
	result[sel_num] = Tree.Items.GetFirstSelectedNode;
	while (Tree.Items.GetNextSelectedNode(result[sel_num]) != 0)
		{
		sel_num++;
		result[sel_num] = Tree.Items.GetNextSelectedNode(result[sel_num-1]);
		}
	}
return result;
}

//############################### Create Checklist ###############################
void sgTree_CreateCheckList(shape FlyTreeControl, dyn_string allItems, dyn_string checkedItems, dyn_string disabled_nodes = EMPTY_DYN_STRING)
{
//this takes all the information necessary for a check list and creates it
sgTree_SetAppearanceAsList(FlyTreeControl);
sgTree_FillList(FlyTreeControl, allItems, TREE_STATE_UNTICKED);
sgTree_TickNamedCheckListItems(FlyTreeControl, checkedItems);

if (dynlen(disabled_nodes) > 0)
	{
	sgTree_SetNamedItemsTo(FlyTreeControl, disabled_nodes, TREE_STATE_UNTICKABLE);	
	}
}

//############################### Create Checklist ###############################
void sgTree_CreateSelectableCheckList(shape FlyTreeControl, dyn_string allItems, dyn_string checkedItems, dyn_string disabled_nodes = EMPTY_DYN_STRING)
{
//this takes all the information necessary for a check list and creates it
sgTree_SetAppearanceAsSelectableList(FlyTreeControl);
sgTree_FillList(FlyTreeControl, allItems, TREE_STATE_UNTICKED);
sgTree_TickNamedCheckListItems(FlyTreeControl, checkedItems);

if (dynlen(disabled_nodes) > 0)
	{
	sgTree_SetNamedItemsTo(FlyTreeControl, disabled_nodes, TREE_STATE_UNTICKABLE);	
	}
}

//############################### Create Radio list ###############################
void sgTree_CreateRadioList(shape FlyTreeControl, dyn_string allItems, string selectedItem)
{
//this takes all the information necessary for a radio list and creates it
sgTree_SetAppearanceAsList(FlyTreeControl);
sgTree_FillList(FlyTreeControl, allItems, TREE_STATE_RADIO_UNSELECTED);
sgTree_SelectItemInRadioList(FlyTreeControl, selectedItem);
}

//############################### Create Tree ###############################
void sgTree_CreateTree(shape FlyTreeControl, dyn_string treeLeaves)
{
//this takes all the information necessary for a tree and creates it
sgTree_SetAppearanceAsTree(FlyTreeControl);
sgTree_InsertDynAsNodes(treeLeaves, FlyTreeControl);
}

//############################### Set Appearance as list ###############################
void sgTree_SetAppearanceAsList(shape Tree)
{
//sets the appearance values of a FlyTree to those necessary to display a list
idispatch columnzero;
columnzero = Tree.Columns.Item(0);
Tree.FitColumnToClientWidth = true;
Tree.FixedRows = 0;
Tree.GridLineWidth = 0;
//Tree.SelectedTextColor = 0;
Tree.SelectedBackgroundColor = Tree.Color;
Tree.ShowLogic = true;
Tree.Showlines = false;
}

//############################### Set Appearance as list ###############################
void sgTree_SetAppearanceAsSelectableList(shape Tree)
{
//sets the appearance values of a FlyTree to those necessary to display a list
idispatch columnzero;
columnzero = Tree.Columns.Item(0);
Tree.FitColumnToClientWidth = true;
Tree.FixedRows = 0;
Tree.GridLineWidth = 0;
Tree.ShowLogic = true;
Tree.Showlines = false;
}


//############################### Set Appearance as tree ###############################
void sgTree_SetAppearanceAsTree(shape Tree)
{
//sets the appearance values of a FlyTree to those necessary to display a tree
idispatch columnzero;
columnzero = Tree.Columns.Item(0);
Tree.FitColumnToClientWidth = true;
Tree.FixedRows = 0;
Tree.GridLineWidth = 0;
Tree.SmoothExpandCollapse = false;
}


//############################### Set up tree as table ###############################
void sgTree_SetUpTreeAsTable(shape Table)
{
//sets the appearance values of a FlyTree to those necessary to display a table
Table.Showlines = false;
Table.ShowButtons = false;
Table.ShowRoot = false;
Table.EditorMode = true;
Table.Items.Clear;
Table.Columns.Clear;
}

//############################### display table ###############################
void sgTree_DisplayTable(shape Table, dyn_dyn_string data, dyn_string column_titles)
{
//displays a table, with some fairly extensive error handling on the input
idispatch curr_node, curr_col;
int col_count = dynlen(data);
bool is_square = true;
int col_width;


if (dynlen(column_titles) < col_count)
	{
	DebugN("not enough column titles");
	}
else
	{
	if (col_count > 0)
		{
		//define columns
		for (int j = 1; j<=dynlen(column_titles);j++)
			{
			Table.Columns.Add(column_titles[j]);
			}
		//insert data
		int row_count = dynlen(data[1]);
		if (row_count > 0)
			{
			for (int x = 2; x <= col_count;x++)
				{
				//check it is a rectangular table!
				is_square = (is_square && (row_count == dynlen(data[x])));
				}
			if (is_square)
				{
				for (int y = 1; y <= row_count ; y++)
					{
					curr_node = Table.ExtractNode(Table.Items.Add(data[1][y]));
					for (int x = 2; x<= col_count; x++)
						{
						curr_node.Cells(x-1) = data[x][y];
						}//inner for (x)
					}//outer for (y)
				}//if is square
			else
				{
				DebugN("not a rectangular table");
				}
			}//if row count > 0
		else
			{
			DebugN("no rows defined in the table supplied");
			}
		}//if col count > 0
	else
		{
		DebugN("displaying table failed, empty data supplied");
		}
	}//if col count < #col titles
}

//############################### create table ###############################
sgTree_CreateTable(shape Table, dyn_dyn_string data, dyn_string column_titles)
{
//creates a table
sgTree_SetUpTreeAsTable(Table);
sgTree_DisplayTable(Table, data, column_titles);
}

//#################### move selected items in a table around... to top, to bottom, up one, down one. #############
sgTree_TableMoveSelectedToTop(shape Table)
{
int INSERT_ON_MOVE = 4;
idispatch curr_node, move_to_node;
curr_node = Table.ExtractNode(Table.Items.GetFirstSelectedNode());
move_to_node = Table.Items.GetFirstNode();
//DebugN(curr_node.Text,"->", move_to_node.Text);
curr_node.MoveTo(move_to_node.ItemId, INSERT_ON_MOVE);
}

sgTree_TableMoveSelectedUpOne(shape Table)
{
int INSERT_ON_MOVE = 4;
idispatch curr_node, move_to_node;
curr_node = Table.ExtractNode(Table.Items.GetFirstSelectedNode());
move_to_node = curr_node.GetPrev();
//DebugN(curr_node.Text,"->", move_to_node.Text);
curr_node.MoveTo(move_to_node.ItemId, INSERT_ON_MOVE);
}

sgTree_TableMoveSelectedDownOne(shape Table)
{
idispatch curr_node, move_to_node, temp;
curr_node = Table.ExtractNode(Table.Items.GetFirstSelectedNode());
move_to_node = curr_node.GetNext();
//DebugN(curr_node.Text,"->", move_to_node.Text);
move_to_node.MoveTo(curr_node.ItemId, 4);
Table.Selected = curr_node.ItemId;

//yes it's wierd, push the one below upwards instead, but it works unlike 'proper' way
//curr_node.MoveTo(move_to_node.ItemId, 0);
}

sgTree_TableMoveSelectedToBottom(shape Table)
{
int INSERT_ON_MOVE = 0;
idispatch curr_node, move_to_node;
curr_node = Table.ExtractNode(Table.Items.GetFirstSelectedNode());
move_to_node = Table.Items.GetLastNode();
//DebugN(curr_node.Text,"->", move_to_node.Text);
curr_node.MoveTo(move_to_node.ItemId, INSERT_ON_MOVE);
}


//######################### get values from a tree set up as a table ##############
dyn_dyn_string sgTree_TableGetValues(shape Table)
{
dyn_dyn_string result;
int col_count, row_count;
idispatch curr_node, test;
test = Table.Columns;
col_count = test.Count;
test = Table.Items;
row_count = test.Count;

DebugN(col_count, row_count);

for (int y = 1;y<= row_count; y++)
	{
	curr_node = Table.GetNodeAtRow(y);
	result[1][y] = curr_node.Text;
	for (int x = 2; x<= col_count;x++)
		{
		result[x][y] = curr_node.Cells(x-1);
		}
	}
return result;
}

//########################## set up tree as a colored picklist table ##########################
void sgTree_SetUpTreeAsColoredPickListTable(shape Tree)
//set up a flytree with the options to make table cells have color (html drawing true)
//and that picklists are visible (totPopupOnClick)
{

//the flytree options are all stored in a single integer, with bits representing values.
//these constants map to each bit.
const int goFixedVertLine			= 1;
const int goFixedHorzLine			= 2;
const int goVertLine					= 4;
const int goHorzLine					= 8;
const int goRangeSelect				= 16;
const int goDrawFocusSelected	= 32;
const int goRowSizing					= 64;
const int goColSizing					= 128;
const int goRowMoving					= 256;
const int goColMoving					= 512;
const int goEditing						= 1024;
const int goTabs							= 2048;
const int goRowSelect					= 4096;
const int goAlwaysShowEditor	= 8192;
const int goThumbTracking			= 16384;

const int totPopupOnClick 		= 1;
const int totRefreshChilds		= 2;
const int totRefreshParents		= 4;
const int totExtendedLogic		= 8;

int defaultOptions = goFixedVertLine + goFixedHorzLine + goVertLine + goHorzLine + goRangeSelect;
int defaultTreeOptions = totRefreshChilds + totRefreshParents;

Tree.Options = defaultOptions + goEditing + goColSizing;
Tree.TreeOptions = defaultTreeOptions + totPopupOnClick;
Tree.HTMLDrawing = true;
Tree.DoubleBuffered = true;
}

//end flytreelib
