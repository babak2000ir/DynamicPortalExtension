table 60000 "TNP Entity Header"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Entity Code"; code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(10; "Entity Name"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(20; "Table ID"; Integer)
        {
            DataClassification = ToBeClassified;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(21; "Table Name"; Text[30])
        {
            FieldClass = FlowField;
            CalcFormula = lookup(AllObjWithCaption."Object Name" where("Object Type" = const(Table), "Object ID" = field("Table ID")));
            Editable = false;
        }
        field(30; "Insert Allowed"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(31; "Insert After Primary Key"; Boolean)
        {
            Caption = 'Insert After Setting Primary Key';
            DataClassification = ToBeClassified;
        }
        field(32; "No Insert Trigger"; Boolean)
        {
            Caption = 'Disable Insert Trigger';
            DataClassification = ToBeClassified;
        }
        field(33; "No Modify Trigger - Insert"; Boolean)
        {
            Caption = 'Disable Modify Trigger on Insert';
            DataClassification = ToBeClassified;
        }
        field(40; "Modify Allowed"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(41; "No Modify Trigger - Modify"; Boolean)
        {
            Caption = 'Disable Modify Trigger on Modify';
            DataClassification = ToBeClassified;
        }
        field(50; "Delete Allowed"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(51; "No Delete Trigger"; Boolean)
        {
            Caption = 'Disable Delete Trigger';
            DataClassification = ToBeClassified;
        }
        field(60; "Rename Allowed"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(61; "No Rename Trigger"; Boolean)
        {
            Caption = 'Disable Rename Trigger';
            DataClassification = ToBeClassified;
        }
        field(62; "Default No. Series"; Code[20])
        {
            Caption = 'Default No. Series';
            DataClassification = ToBeClassified;
            TableRelation = "No. Series";
        }
    }

    keys
    {
        key(Key1; "Entity Code")
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    var
        EntityRelationTableFilter: Record "TNP Ent. Rel. Table Filter";
        EntityField: Record "TNP Entity Field";
    begin
        EntityField.reset();
        EntityField.SetRange("Entity code", "Entity Code");
        EntityField.DeleteAll(true);

        EntityRelationTableFilter.reset();
        EntityRelationTableFilter.SetRange("Entity Code", "Entity Code");
        EntityRelationTableFilter.DeleteAll(true);
    end;
}