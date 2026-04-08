import { buildCollection, buildProperty } from "@firecms/core";
import { assessmentsCollection } from "./assessments";

export type Course = {
    name: string;
    professor: string;
    credits: number;
    colorValue: number;
    isPassFail: boolean;
    semesterId: any; // Reference
    courseworkWeight: number;
    finalWeight: number;
    lectureTime: string;
    hasLab: boolean;
    hasTutorial: boolean;
};

export const coursesCollection = buildCollection<Course>({
    id: "courses",
    name: "Courses",
    singularName: "Course",
    path: "courses",
    icon: "School",
    group: "Academic",
    subcollections: [assessmentsCollection],
    properties: {
        name: buildProperty({
            name: "Name",
            dataType: "string",
            validation: { required: true }
        }),
        professor: buildProperty({
            name: "Professor",
            dataType: "string",
            validation: { required: true }
        }),
        credits: buildProperty({
            name: "Credits",
            dataType: "number",
            validation: { required: true }
        }),
        colorValue: buildProperty({
            name: "Color (ARGB)",
            dataType: "number",
            description: "ARGB integer value"
        }),
        isPassFail: buildProperty({
            name: "Pass/Fail Mode",
            dataType: "boolean"
        }),
        semesterId: buildProperty({
            name: "Semester",
            dataType: "reference",
            path: "semesters"
        }),
        courseworkWeight: buildProperty({
            name: "Coursework Weight",
            dataType: "number",
            defaultValue: 60
        }),
        finalWeight: buildProperty({
            name: "Final/Project Weight",
            dataType: "number",
            defaultValue: 40
        }),
        lectureTime: buildProperty({
            name: "Lecture Time",
            dataType: "string",
            description: "Format: Day HH:mm"
        }),
        hasLab: buildProperty({
            name: "Has Lab",
            dataType: "boolean"
        }),
        hasTutorial: buildProperty({
            name: "Has Tutorial",
            dataType: "boolean"
        })
    }
});
