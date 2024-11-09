table 60003 "TNP Ent. Rel. Table Filter"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Entity Code"; Code[20])
        {
            DataClassification = ToBeClassified;
        }

        field(2; "Related Table ID"; Integer)
        {
            DataClassification = ToBeClassified;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(10; "Related Table Field ID"; Integer)
        {
            DataClassification = ToBeClassified;

            trigger OnLookup()
            var
                FieldRecord: Record Field;
                FieldLookup: page "Fields Lookup";
            begin
                FieldRecord.Reset();
                FieldRecord.SetRange(TableNo, Rec."Related Table ID");
                FieldLookup.SetTableView(FieldRecord);
                FieldLookup.LookupMode(true);
                if FieldLookup.RunModal() = Action::LookupOK then begin
                    FieldLookup.GetRecord(FieldRecord);
                    "Related Table Field ID" := FieldRecord."No.";
                    "Related Table Field Name" := FieldRecord.FieldName;
                end;
            end;

            trigger OnValidate()
            begin
                if "Related Table Field ID" = 0 then
                    "Related Table Field Name" := '';
            end;
        }
        field(11; "Related Table Field Name"; Text[30])
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(20; "Field Relation"; Option)
        {
            DataClassification = ToBeClassified;
            OptionMembers = "Const",Field,Filter;
        }
        field(30; "Const/Filter Value"; Text[250])
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()
            begin
                "Entity Header Field ID" := 0;
                "Entity Header Field Name" := '';
            end;
        }
        field(40; "Entity Header Field ID"; Integer)
        {
            DataClassification = ToBeClassified;

            trigger OnLookup()
            var
                EntityHeader: Record "TNP Entity Header";
                FieldRecord: Record Field;
                FieldLookup: page "Fields Lookup";
            begin
                if EntityHeader.Get(Rec."Entity Code") then begin
                    FieldRecord.Reset();
                    FieldRecord.SetRange(TableNo, EntityHeader."Table ID");
                    FieldLookup.SetTableView(FieldRecord);
                    FieldLookup.LookupMode(true);
                    if FieldLookup.RunModal() = Action::LookupOK then begin
                        FieldLookup.GetRecord(FieldRecord);
                        "Entity Header Field ID" := FieldRecord."No.";
                        "Entity Header Field Name" := FieldRecord.FieldName;
                        "Const/Filter Value" := '';
                    end;
                end;
            end;

            trigger OnValidate()
            begin
                if "Entity Header Field ID" = 0 then
                    "Entity Header Field Name" := '';

                "Const/Filter Value" := '';
            end;
        }
        field(41; "Entity Header Field Name"; Text[30])
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Entity Code", "Related Table ID", "Related Table Field ID")
        {
            Clustered = true;
        }
    }
}