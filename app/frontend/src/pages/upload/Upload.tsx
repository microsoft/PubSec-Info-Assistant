// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { FilePicker } from "../../components/filepicker/file-picker";
import styles from "./Upload.module.css";

const Upload = () => {
    return (
        <div className={styles.App} >
            <FilePicker uploadURL={"http://dlptest.com/http-post/"} />
        </div>
    );
};
    
export default Upload;