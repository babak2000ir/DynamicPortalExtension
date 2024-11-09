page 60001 "TNP Entity Field List"
{
    PageType = ListPart;
    SourceTable = "TNP Entity Field";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Entity Code"; Rec."Entity Code")
                {
                    ToolTip = 'Specifies the value of the Entity Code field.';
                    Visible = false;
                }
                field("Field ID"; Rec."Field ID")
                {
                    ToolTip = 'Specifies the value of the Field ID field.';
                }
                field("Field Name"; Rec."Field Name")
                {
                    ToolTip = 'Specifies the value of the Field Name field.';
                }
                field("Read Only"; Rec."Read Only")
                {
                    ToolTip = 'Specifies the value of the Read Only field.';
                }
                field("Validatation - Insert"; Rec."Validatation - Insert")
                {
                    ToolTip = 'Specifies the value of the Validatation - Insert field.';
                    Enabled = not Rec."Read Only";
                }
                field("Validatation - Modify"; Rec."Validatation - Modify")
                {
                    ToolTip = 'Specifies the value of the Validatation - Modify field.';
                    Enabled = not Rec."Read Only";
                }
                field("Validatation - Rename"; Rec."Validatation - Rename")
                {
                    ToolTip = 'Specifies the value of the Validatation - Rename field.';
                    Enabled = not Rec."Read Only";
                }
            }
        }
    }
}