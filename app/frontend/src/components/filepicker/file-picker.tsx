// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import classNames from "classnames";  
import { nanoid } from "nanoid";  
import { useCallback, useEffect, useMemo, useState } from "react"; 
import { SpinnerIos16Filled } from "@fluentui/react-icons"; 
import { DropZone } from "./drop-zone";  
import styles from "./file-picker.module.css";  
import { FilesList } from "./files-list";  
import { logStatus, StatusLogClassification, StatusLogEntry, StatusLogState } from "../../api";  
  
interface Props {  
  folderPath: string;  
  tags: string[];  
}  
  
const FilePicker = ({ folderPath, tags }: Props) => {  
  const [files, setFiles] = useState<any>([]);  
  const [progress, setProgress] = useState(0);  
  const [uploadStarted, setUploadStarted] = useState(false);  
  
  // handler called when files are selected via the Dropzone component  
  const handleOnChange = useCallback((files: any) => {  
    let filesArray = Array.from(files);  
    filesArray = filesArray.map((file) => ({  
      id: nanoid(),  
      file,  
    }));  
    setFiles(filesArray as any);  
    setProgress(0);  
    setUploadStarted(false);  
  }, []);  
  
  // handle for removing files form the files list view  
  const handleClearFile = useCallback((id: any) => {  
    setFiles((prev: any) => prev.filter((file: any) => file.id !== id));  
  }, []);  
  
  // whether to show the progress bar or not  
  const canShowProgress = useMemo(() => files.length > 0, [files.length]);  
  
  // execute the upload operation  
  const handleUpload = useCallback(async () => {  
    try {  
      const data = new FormData();  
      console.log("files", files);  
      setUploadStarted(true);  
      let uploadedFilesCount = 0;
  
      const uploadPromises = files.map(async (indexedFile:any, index:any) => {  
        const file = indexedFile.file as File;  
        const filePath = folderPath === "" ? file.name : `${folderPath}/${file.name}`;  
  
        // Append file and other data to FormData  
        data.append("file", file);  
        data.append("file_path", filePath);  
        
        if (tags.length > 0) {
          data.append("tags", tags.map(encodeURIComponent).join(",")); 
        }
  
        try {  
          const response = await fetch("/file", {  
            method: "POST",  
            body: data,  
          });  
  
          if (!response.ok) {  
            throw new Error(`Failed to upload file: ${filePath}`);  
          }  
  
          const result = await response.json();  
          console.log(result);  
  
          // Write status to log  
          const logEntry: StatusLogEntry = {  
            path: "upload/" + filePath,  
            status: "File uploaded from browser to backend API",  
            status_classification: StatusLogClassification.Info,  
            state: StatusLogState.Uploaded,  
          };  
          await logStatus(logEntry);
          
        } catch (error) {  
          console.log("Unable to upload file " + filePath + " : Error: " + error);  
        }  
        // Increment the counter for successfully uploaded files
        uploadedFilesCount++;
        setProgress((uploadedFilesCount / files.length) * 100);
      
      });
  
      await Promise.all(uploadPromises);  
      setUploadStarted(false);  
    } catch (error) {  
      console.log(error);  
    }  
  }, [files, folderPath, tags]);
  
  // set progress to zero when there are no files  
  useEffect(() => {  
    if (files.length < 1) {  
      setProgress(0);  
    }  
  }, [files.length]);  
  
  // set uploadStarted to false when the upload is complete  
  useEffect(() => {  
    if (progress === 100) {  
      setUploadStarted(false);  
    }  
  }, [progress]);  
  
  const uploadComplete = useMemo(() => progress === 100, [progress]);  
  
  return (  
    <div className={styles.wrapper}>  
      {/* canvas */}  
      <div className={styles.canvas_wrapper}>  
        <DropZone onChange={handleOnChange} accept={files} />  
      </div>  
      {/* files listing */}  
      {files.length ? (  
        <div className={styles.files_list_wrapper}>
          {uploadStarted && (
            <div className={styles.spinner_overlay}>
              <SpinnerIos16Filled className={styles.spinner} />
            </div>
          )}  
          <FilesList  
            files={files}  
            onClear={handleClearFile}  
            uploadComplete={uploadComplete}  
          />  
        </div>  
      ) : null}  
      {/* progress bar */}  
      {canShowProgress ? (  
        <div className={styles.files_list_progress_wrapper}>  
          <progress value={progress} max={100} style={{ width: "100%" }} />  
        </div>  
      ) : null}  
      {/* upload button */}  
      {files.length ? (  
        <button  
          onClick={handleUpload}  
          className={classNames(  
            styles.upload_button,  
            uploadComplete || uploadStarted ? styles.disabled : ""  
          )}  
          aria-label="upload files"  
        >  
          {`Upload ${files.length} Files`}  
        </button>  
      ) : null}  
    </div>  
  );  
};  
  
export { FilePicker };  
