import { buildCollection, buildProperty } from "@firecms/core";

export type Assessment = {
    title: string;
    type: string;
    category: string;
    weight: number;
    maxScore: number;
    score?: number;
    deadline?: Date;
    isCompleted: boolean;
};

export const assessmentsCollection = buildCollection<Assessment>({
    id: "assessments",
    name: "Assessments",
    singularName: "Assessment",
    path: "assessments",
    icon: "Assignment",
    properties: {
        title: buildProperty({
            name: "Title",
            dataType: "string",
            validation: { required: true }
        }),
        type: buildProperty({
            name: "Type",
            dataType: "string",
            enumValues: {
                quiz: "Quiz",
                assignment: "Assignment",
                midterm: "Midterm",
                finalExam: "Final Exam",
                project: "Project",
                other: "Other"
            },
            validation: { required: true }
        }),
        category: buildProperty({
            name: "Category",
            dataType: "string",
            enumValues: {
                coursework: "Coursework",
                finalProject: "Final/Project"
            },
            validation: { required: true }
        }),
        weight: buildProperty({
            name: "Weight (Points)",
            dataType: "number",
            validation: { required: true }
        }),
        maxScore: buildProperty({
            name: "Max Score",
            dataType: "number",
            defaultValue: 100
        }),
        score: buildProperty({
            name: "Score",
            dataType: "number"
        }),
        deadline: buildProperty({
            name: "Deadline",
            dataType: "date"
        }),
        isCompleted: buildProperty({
            name: "Is Completed",
            dataType: "boolean",
            defaultValue: false
        })
    }
});
