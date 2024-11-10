page 60000 "TNP Entity List"
{
    PageType = List;
    UsageCategory = Lists;
    ApplicationArea = All;
    SourceTable = "TNP Entity Header";

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Entity Code"; Rec."Entity Code")
                {
                    ToolTip = 'Specifies the value of the Entity Code field.';
                }
                field("Entity Name"; Rec."Entity Name")
                {
                    ToolTip = 'Specifies the value of the Entity Name field.';
                }
                field("Table ID"; Rec."Table ID")
                {
                    ToolTip = 'Specifies the value of the Table ID field.';
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
                    end;
                }
                field("Table Name"; Rec."Table Name")
                {
                    ToolTip = 'Specifies the value of the Table Name field.';
                    ApplicationArea = All;
                }
                field("Insert Allowed"; Rec."Insert Allowed")
                {
                    ToolTip = 'Specifies the value of the Insert Allowed field.';
                    ApplicationArea = All;
                }
                field("Modify Allowed"; Rec."Modify Allowed")
                {
                    ToolTip = 'Specifies the value of the Modify Allowed field.';
                    ApplicationArea = All;
                }
                field("Delete Allowed"; Rec."Delete Allowed")
                {
                    ToolTip = 'Specifies the value of the Delete Allowed field.';
                    ApplicationArea = All;
                }

                field("Rename Allowed"; Rec."Rename Allowed")
                {
                    ToolTip = 'Specifies the value of the Rename Allowed field.';
                    ApplicationArea = All;
                }

            }
            group(HeaderGroup)
            {
                group(InsertGroup)
                {
                    Caption = 'Insert';
                    Visible = Rec."Insert Allowed";

                    field("Insert After Primary Key"; Rec."Insert After Primary Key")
                    {
                        ToolTip = 'Specifies the value of the Insert After Setting Primary Key field.';
                        ApplicationArea = All;
                    }
                    field("No Insert Trigger"; Rec."No Insert Trigger")
                    {
                        ToolTip = 'Specifies the value of the Disable Insert Trigger field.';
                        ApplicationArea = All;
                    }
                    field("No Modify Trigger - Insert"; Rec."No Modify Trigger - Insert")
                    {
                        ToolTip = 'Specifies the value of the Disable Modify Trigger on Insert field.';
                        ApplicationArea = All;
                    }
                }
                group(ModifyGroup)
                {
                    Caption = 'Modify';
                    Visible = Rec."Modify Allowed";

                    field("No Modify Trigger - Modify"; Rec."No Modify Trigger - Modify")
                    {
                        ToolTip = 'Specifies the value of the Disable Modify Trigger on Modify field.';
                        ApplicationArea = All;
                    }
                }
                group(DeleteGroup)
                {
                    Caption = 'Delete';
                    Visible = Rec."Delete Allowed";

                    field("No Delete Trigger"; Rec."No Delete Trigger")
                    {
                        ToolTip = 'Specifies the value of the Disable Delete Trigger field.';
                        ApplicationArea = All;
                    }
                }
                group(RenameGroup)
                {
                    Caption = 'Rename';
                    Visible = Rec."Rename Allowed";

                    field("No Rename Trigger"; Rec."No Rename Trigger")
                    {
                        ToolTip = 'Specifies the value of the Disable Rename Trigger field.';
                        ApplicationArea = All;
                    }
                }

                group(setGroup)
                {
                    Caption = 'Set';
                    Visible = true;

                    field("Default No. Series"; Rec."Default No. Series")
                    {
                        ToolTip = 'Specifies the value of the Default No. Series field.';
                        ApplicationArea = All;
                    }
                }
            }
            group(FieldsGroup)
            {
                part("TNP Entity Field List"; "TNP Entity Field List")
                {
                    ApplicationArea = All;
                    SubPageLink = "Entity Code" = field("Entity Code");
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RelatedTables)
            {
                ToolTip = 'Displays the related tables for the current entity.';
                ApplicationArea = All;
                Caption = 'Related Tables';
                Promoted = true;
                PromotedCategory = Process;
                Image = Relationship;
                RunObject = page "Entity Related List";
                RunPageLink = "Entity Code" = field("Entity Code");
                PromotedIsBig = true;
            }

            //TODO: Add action for Entity Filter
        }
    }


}