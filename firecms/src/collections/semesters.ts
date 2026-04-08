import { buildCollection, buildProperty } from "@firecms/core";

export type Semester = {
    name: string;
    startDate: Date;
    endDate: Date;
    active: boolean;
};

export const semestersCollection = buildCollection<Semester>({
    id: "semesters",
    name: "Semesters",
    singularName: "Semester",
    path: "semesters",
    icon: "CalendarMonth",
    group: "Academic",
    properties: {
        name: buildProperty({
            name: "Name",
            dataType: "string",
            validation: { required: true }
        }),
        startDate: buildProperty({
            name: "Start Date",
            dataType: "date",
            validation: { required: true }
        }),
        endDate: buildProperty({
            name: "End Date",
            dataType: "date",
            validation: { required: true }
        }),
        active: buildProperty({
            name: "Active",
            dataType: "boolean",
            defaultValue: false
        })
    }
});
