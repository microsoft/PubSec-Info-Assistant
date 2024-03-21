// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { BlobServiceClient } from "@azure/storage-blob";
import classNames from "classnames";
import { nanoid } from "nanoid";
import { useCallback, useEffect, useMemo, useState } from "react";
import { DropZone } from "./drop-zone"
import styles from "./file-picker.module.css";
import { FilesList } from "./files-list";
import { getBlobClientUrl, logStatus, StatusLogClassification, StatusLogEntry, StatusLogState } from "../../api"
import cstyle from "./tda.module.css" 

interface Props {
  folderPath: string;
  tags: string[];
}

const Tda = ({folderPath, tags}: Props) => {
  const [files, setFiles] = useState<any>([]);
  const [progress, setProgress] = useState(0);
  const [uploadStarted, setUploadStarted] = useState(false);
  const folderName = folderPath;
  const tagList = tags;
  const [fileUploaded, setFileUploaded] = useState(false);
  const [output, setOutput] = useState('');
  const [selectedQuery, setSelectedQuery] = useState('');


  const handleAnalysis = () => {
    // Handle the analysis here
  };
  
  const handleAnswer = () => {
    // Handle the answer here
  };

  // handler called when files are selected via the Dropzone component

  const handleQueryChange = (event: { target: { value: any; }; }) => {
    const query = event.target.value;
    setSelectedQuery(query);
    // Handle the selected query here
  };
  
  const handleOnChange = useCallback((files: any) => {

    let filesArray = Array.from(files);

    filesArray = filesArray.map((file) => ({
      id: nanoid(),
      file
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
      

      var counter = 1;
      files.forEach(async (indexedFile: any) => {
        var file = indexedFile.file as File;
        var filePath = (folderName == "") ? file.name : folderName + "/" + file.name;
        // set mimetype as determined from browser with file upload control
        const options = {
          blobHTTPHeaders: { blobContentType: file.type },
          metadata: { tags: tagList.map(encodeURIComponent).join(",") }
        };

        //write status to log
        var logEntry: StatusLogEntry = {
          path: "upload/"+filePath,
          status: "File uploaded from browser to Azure Blob Storage",
          status_classification: StatusLogClassification.Info,
          state: StatusLogState.Uploaded
        }
        await logStatus(logEntry);

        setProgress((counter/files.length) * 100);
        counter++;
      });

      setUploadStarted(false);
    } catch (error) {
      console.log(error);
    }
  }, [files.length]);

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

  return (<div>
    <div className={cstyle.centeredContainer}>
      <p>Upload a CSV file</p>
    
    <div className={styles.wrapper}>
      
      {/* canvas */}
      <div className={styles.canvas_wrapper}>
        <DropZone onChange={handleOnChange} accept={files} />
      </div>

      {/* files listing */}
      {files.length ? (
        <div className={styles.files_list_wrapper}>
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
    <div>
      <p>Select an example query:</p>
      <select onChange={handleQueryChange}>
        <option value="rows">How many rows are there?</option>
        <option value="dataType">What is the data type of each column?</option>
        <option value="summaryStats">What are the summary statistics for categorical data?</option>
        <option value="other">Other</option>
    </select>
  {selectedQuery === 'other' && (
    <div className={cstyle.centeredContainer}>
    <p>Ask a question about your CSV:</p>
      <input type="text" placeholder="Enter your query" />
      </div>
      
    )}
      </div>
      
      
    </div>
    <h1>Ouput</h1>
    <div className={cstyle.centeredContainer}>
    <details>
  <summary>See Dataframe</summary>
  <div>
    {/* Display the dataframe here */}
  </div>
</details>
    </div>
  <div className={cstyle.centeredContainer}>
    <button onClick={handleAnalysis}>Here is my analysis</button>
    <button onClick={handleAnswer}>Show me the answer</button>
</div>
{ output && (
      <div>
        
        <p>{output}</p>
      </div>
    )}
</div>
  );
};

export { Tda };
