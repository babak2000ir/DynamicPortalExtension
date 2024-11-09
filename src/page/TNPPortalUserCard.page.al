page 60005 "TNP Portal User Card"
{
    PageType = Card;
    UsageCategory = Documents;
    ApplicationArea = All;
    SourceTable = "TNP Portal User";
    Caption = 'Portal User Card';

    layout
    {
        area(Content)
        {
            group(General)
            {

                field("User Email"; Rec."User Email")
                {
                    ToolTip = 'Specifies the value of the User Email field.';
                    trigger OnValidate()
                    var
                        EmailPart1: Text;
                    begin
                        EmailPart1 := SelectStr(1, ConvertStr(Rec."User Email", '@', ','));
                        if Rec."User ID" = '' then
                            Rec."User ID" := EmailPart1;

                        if Rec."Full Name" = '' then
                            Rec."Full Name" := ConvertStr(EmailPart1, '.', ' ');
                    end;
                }
                field("User ID"; Rec."User ID")
                {
                    ToolTip = 'Specifies the value of the User ID field.';
                }
                field("Full Name"; Rec."Full Name")
                {
                    ToolTip = 'Specifies the value of the Full Name field.';
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ToolTip = 'Specifies the value of the Phone No. field.';
                }
                field(Enabled; Rec.Enabled)
                {
                    ToolTip = 'Specifies the value of the Enabled field.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(GeneratePassword)
            {
                Caption = 'Generate Password';
                ToolTip = 'Generate Password';
                Image = CreateSerialNo;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ApplicationArea = All;

                trigger OnAction()
                var
                    PortalUserMgmt: Codeunit "TNP Portal User Management";
                begin
                    PortalUserMgmt.CreatePasswordManually(Rec);
                end;
            }
        }
    }
}