page 60049 "AllTable"
{
    PageType = List;
    UsageCategory = Lists;
    ApplicationArea = All;
    SourceTable = AllObjWithCaption;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {

                field("App Package ID"; Rec."App Package ID")
                {
                    ToolTip = 'Specifies the value of the App Package ID field.';
                }
                field("App Runtime Package ID"; Rec."App Runtime Package ID")
                {
                    ToolTip = 'Specifies the value of the App Runtime Package ID field.';
                }
                field("Object Caption"; Rec."Object Caption")
                {
                    ToolTip = 'Specifies the caption of the object.';
                }
                field("Object ID"; Rec."Object ID")
                {
                    ToolTip = 'Specifies the object ID.';
                }
                field("Object Name"; Rec."Object Name")
                {
                    ToolTip = 'Specifies the name of the object.';
                }
                field("Object Subtype"; Rec."Object Subtype")
                {
                    ToolTip = 'Specifies the subtype of the object.';
                }
                field("Object Type"; Rec."Object Type")
                {
                    ToolTip = 'Specifies the object type.';
                }
            }
        }

    }
}