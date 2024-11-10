table 60001 "TNP Entity Field"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Entity Code"; Code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(2; "Field ID"; Integer)
        {
            DataClassification = ToBeClassified;

            trigger OnLookup()
            var
                FieldRecord: Record Field;
                EntityHeader: Record "TNP Entity Header";
                FieldLookup: page "Fields Lookup";
            begin
                if EntityHeader.Get(rec."Entity Code") then begin
                    FieldRecord.Reset();
                    FieldRecord.SetRange(TableNo, EntityHeader."Table ID");
                    FieldLookup.SetTableView(FieldRecord);
                    FieldLookup.LookupMode(true);
                    if FieldLookup.RunModal() = Action::LookupOK then begin
                        FieldLookup.GetRecord(FieldRecord);
                        "Field ID" := FieldRecord."No.";
                        "Field Name" := FieldRecord.FieldName;
                    end;
                end;
            end;

            trigger OnValidate()
            begin
                if "Field ID" = 0 then
                    "Field Name" := '';
            end;
        }
        field(11; "Field Name"; Text[30])
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(12; "Read Only"; Boolean)
        {
            DataClassification = ToBeClassified;
        }

        field(21; "Validatation - Insert"; option)
        {
            DataClassification = ToBeClassified;
            OptionMembers = "Validate On Insert","Assign & Validate On Insert","No Validation On Insert";
        }
        field(22; "Validatation - Modify"; option)
        {
            DataClassification = ToBeClassified;
            OptionMembers = "Validate On Modify","Assign & Validate On Modify","No Validation On Modify";
        }
        field(23; "Validatation - Rename"; option)
        {
            DataClassification = ToBeClassified;
            OptionMembers = "Validate On Rename","Assign & Validate On Rename","No Validation On Rename";
        }
        field(30; "Primary Key"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(Key1; "Entity code", "Field ID")
        {
            Clustered = true;
        }
    }

    var
        EntityMgmt: Codeunit "TPE Entity Management";

    trigger OnInsert()
    var
        Entity: Record "TNP Entity Header";
    begin
        if Entity.Get(Rec."Entity Code") and
                    (this.EntityMgmt.IsPrimaryKey(Entity."Table ID", Rec."Field ID") or
                    this.EntityMgmt.isFlowField(Entity."Table ID", Rec."Field ID")) then begin
            Rec."Primary Key" := true;
            Rec."Read Only" := true;
        end;
    end;
}