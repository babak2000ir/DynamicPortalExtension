table 60004 "TNP Portal User"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "User ID"; Code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(2; "User Email"; Text[250])
        {
            DataClassification = ToBeClassified;
            OptimizeForTextSearch = true;
            trigger onValidate()
            begin
                if this.UserExistsByEmail("User Email") then
                    Error('User with this email already exists.');
                Rec.Validate("User Email UC", ConvertStr("User Email", '@', '¬'));
            end;
        }
        field(3; "User Email UC"; Code[250])
        {
            DataClassification = ToBeClassified;
            OptimizeForTextSearch = true;
            Editable = false;
        }
        field(10; "Full Name"; Text[80])
        {
            Caption = 'Full Name';
        }
        field(11; "Phone No."; Text[30])
        {
            ExtendedDatatype = PhoneNo;
        }
        field(20; "Password Hash"; Text[32])
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(21; "Salt"; Text[50])
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(30; Enabled; Boolean)
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(PK; "User ID")
        {
            Clustered = true;
        }
    }

    procedure UserExistsByEmail(UserEmail: Text[250]): Boolean
    var
        DummyRec: Record "TNP Portal User";
    begin
        exit(this.FindUserByEmail(UserEmail, DummyRec));
    end;

    procedure FindUserByEmail(UserEmail: Text[250]; var PortalUser: Record "TNP Portal User"): Boolean
    begin
        PortalUser.Reset();
        PortalUSer.SetRange("User Email UC", ConvertStr(UpperCase("User Email"), '@', '¬'));
        if PortalUser.FindFirst() then
            exit(true);
    end;

    procedure FindUserByEmail(UserEmail: Text[250]): Boolean
    begin
        exit(this.FindUserByEmail(UserEmail, Rec));
    end;
}