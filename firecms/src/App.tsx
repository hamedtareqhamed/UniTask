import React from "react";
import { FireCMSFirebaseApp } from "@firecms/firebase";
import { semestersCollection } from "./collections/semesters";
import { coursesCollection } from "./collections/courses";
import { firebaseConfig } from "./firebase_config";

/**
 * FireCMS v3 Entry Point using the unified Firebase App component.
 * This component orchestrates Auth, Firestore, and Storage automatically.
 */
export default function App() {
    return (
        <FireCMSFirebaseApp
            name={"UniTask Manager"}
            logo={"https://firecms.co/img/logo.svg"}
            collections={[
                semestersCollection,
                coursesCollection
            ]}
            firebaseConfig={firebaseConfig}
            // The admin is hosted at /admin in the flutter project
            basePath="admin"
        />
    );
}
