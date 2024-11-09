page 60006 "TNP Entity Setup"
{
    PageType = Card;
    UsageCategory = Administration;
    ApplicationArea = All;
    SourceTable = "TNP Entity Setup";
    Caption = 'TNP Entity Setup';

    layout
    {
        area(Content)
        {
            group("Portal Setup")
            {
                Caption = 'Portal Setup';

                field("Portal Base URL"; Rec."Portal Base URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Portal Base URL field.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end
    end;
}