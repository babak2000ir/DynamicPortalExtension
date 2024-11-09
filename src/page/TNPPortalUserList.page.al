page 60004 "TNP Portal User List"
{
    PageType = List;
    UsageCategory = Lists;
    ApplicationArea = All;
    SourceTable = "TNP Portal User";
    Caption = 'Portal User List';
    CardPageId = "TNP Portal User Card";

    layout
    {
        area(content)
        {
            repeater(Group)
            {

                field("User ID"; Rec."User ID")
                {
                    ToolTip = 'Specifies the value of the User ID field.';
                    ApplicationArea = All;
                }
                field("User Email"; Rec."User Email")
                {
                    ToolTip = 'Specifies the value of the User Email field.';
                    ApplicationArea = All;
                }
                field("Full Name"; Rec."Full Name")
                {
                    ToolTip = 'Specifies the value of the Full Name field.';
                    ApplicationArea = All;
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ToolTip = 'Specifies the value of the Phone No. field.';
                    ApplicationArea = All;
                }
                field(Enabled; Rec.Enabled)
                {
                    ToolTip = 'Specifies the value of the Enabled field.';
                    ApplicationArea = All;
                }
            }
        }
    }
}
