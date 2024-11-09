codeunit 60002 "TNP Portal User Management"
{
    var
        CrptographyMgmt: Codeunit "Cryptography Management";

    procedure GenerateSalt(): Text[32]
    begin
        exit(this.GenerateSalt(32));
    end;

    procedure GenerateSalt(SaltLength: Integer): Text
    var
        Salt: Text;
        i: Integer;
        RandomInt: Char;
    begin
        if SaltLength <= 0 then SaltLength := 32;

        Salt := '';
        Randomize();
        for i := 1 to SaltLength do begin
            RandomInt := Random(255) + 256;
            Salt := Salt + RandomInt;
        end;

        exit(Salt);
    end;

    procedure GenerateRandomPassword(PasswordLength: Integer): Text
    var
        Password: Text;
        i: Integer;
        RandomInt: Char;
    begin
        if PasswordLength <= 0 then PasswordLength := 8;

        Password := '';
        Randomize();
        for i := 1 to PasswordLength do begin
            RandomInt := Random(93) + 33;
            Password := Password + RandomInt;
        end;

        exit(Password);
    end;

    procedure GeneratePasswordHash(Password: Text; Salt: Text): Text[32]
    begin
        exit(this.CrptographyMgmt.GenerateHash(Password + Salt, Enum::"Hash Algorithm"::SHA256));
    end;

    procedure CreatePasswordManually(var User: Record "TNP Portal User")
    var
        Password: Text;
    begin
        if (User."User ID" = '') or (User."User Email" = '') then
            Error('User ID and User Email must be filled.');

        Password := this.GenerateRandomPassword(8);
        this.CreatePassword(User, Password);

        Message('Write down this password: [%1], you won''t be able to retrive it again.', Password);
    end;

    procedure CreatePassword(var User: Record "TNP Portal User"; password: Text)
    var
        Salt: Text[50];
    begin
        if (User."User ID" = '') or (User."User Email" = '') then
            Error('User ID and User Email must be filled.');

        Salt := this.GenerateSalt();
        User."Password Hash" := this.GeneratePasswordHash(Password, Salt);
        User.Salt := Salt;
        User.Enabled := true;
        User.Modify();
    end;

    procedure ValidatePasswordByEmail(UserEmail: Text[250]; Password: Text; var PortalUser: Record "TNP Portal User"): Boolean

    begin
        if PortalUser.FindUserByEmail(UserEmail) then
            if PortalUser."Password Hash" = this.GeneratePasswordHash(Password, PortalUser.Salt) then
                exit(true);
    end;
}

