page 60003 "TNP Ent. Rel. Tbl. Filter List"
{
    Caption = 'Entity Related Table Filter List';
    PageType = ListPart;
    UsageCategory = Lists;
    ApplicationArea = All;
    SourceTable = "TNP Ent. Rel. Table Filter";

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
                field("Related Table ID"; Rec."Related Table ID")
                {
                    ToolTip = 'Specifies the value of the Related Table ID field.';
                    Visible = false;
                }
                field("Related Table Field ID"; Rec."Related Table Field ID")
                {
                    ToolTip = 'Specifies the value of the Related Table Field ID field.';
                }
                field("Related Table Field Name"; Rec."Related Table Field Name")
                {
                    ToolTip = 'Specifies the value of the Related Table Field Name field.';
                }
                field("Field Relation"; Rec."Field Relation")
                {
                    ToolTip = 'Specifies the value of the Field Relation field.';
                }
                field("Const/Filter Value"; Rec."Const/Filter Value")
                {
                    ToolTip = 'Specifies the value of the Const/Filter Value field.';
                    Enabled = (Rec."Field Relation" = Rec."Field Relation"::Const) or (Rec."Field Relation" = Rec."Field Relation"::Filter);
                }
                field("Entity Header Field ID"; Rec."Entity Header Field ID")
                {
                    ToolTip = 'Specifies the value of the Entity Header Field ID field.';
                    Enabled = Rec."Field Relation" = Rec."Field Relation"::Field;
                }
                field("Entity Header Field Name"; Rec."Entity Header Field Name")
                {
                    ToolTip = 'Specifies the value of the Entity Header Field Name field.';
                    Enabled = Rec."Field Relation" = Rec."Field Relation"::Field;
                }
            }
        }
    }
}