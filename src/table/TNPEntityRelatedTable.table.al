table 60002 "TNP Entity Related Table"
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
        field(10; "Related Table Name"; Text[30])
        {
            FieldClass = FlowField;
            CalcFormula = lookup(AllObjWithCaption."Object Name" where("Object Type" = const(Table), "Object ID" = field("Related Table ID")));
            Editable = false;
        }
        field(20; "Related Entity"; Code[20])
        {
            TableRelation = "TNP Entity Header"."Entity Code" where("Table ID" = field("Related Table ID"));
        }
    }

    keys
    {
        key(Key1; "Entity Code", "Related Table ID")
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    var
        EntityRelatedTableFilter: Record "TNP Ent. Rel. Table Filter";
    begin
        EntityRelatedTableFilter.Reset();
        EntityRelatedTableFilter.SetRange("Entity Code", Rec."Entity Code");
        EntityRelatedTableFilter.SetRange("Related Table ID", Rec."Related Table ID");
        EntityRelatedTableFilter.DeleteAll(true);
    end;
}