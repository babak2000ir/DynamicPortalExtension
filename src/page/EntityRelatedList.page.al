page 60002 "Entity Related List"
{
    Caption = 'PageName';
    PageType = List;
    UsageCategory = Lists;
    ApplicationArea = All;
    SourceTable = "TNP Entity Related Table";

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
                }
                field("Related Table Name"; Rec."Related Table Name")
                {
                    ToolTip = 'Specifies the value of the Related Table Name field.';
                }
                field("Related Entity"; Rec."Related Entity")
                {
                    ToolTip = 'Specifies the value of the Related Entity field.';
                }
            }
            group(FieldRelationGroup)
            {
                part("TNP Ent. Rel. Tbl. Filter List"; "TNP Ent. Rel. Tbl. Filter List")
                {
                    ApplicationArea = All;
                    SubPageLink = "Entity Code" = field("Entity Code"), "Related Table ID" = field("Related Table ID");
                }
            }
        }
    }

}