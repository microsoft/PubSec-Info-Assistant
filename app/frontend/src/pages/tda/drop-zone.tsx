// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { array, func } from "prop-types";
import React from "react";
import styles from "./drop-zone.module.css";

const Banner = ({ onClick, onDrop }: {onClick: any, onDrop: any}) => {
  const handleDragOver = (ev: any) => {
    ev.preventDefault();
    ev.stopPropagation();
    ev.dataTransfer.dropEffect = "copy";
  };

  const handleDrop = (ev: any) => {
    ev.preventDefault();
    ev.stopPropagation();
    onDrop(ev.dataTransfer.files);
  };

  return (
    <div
      className={styles.banner}
      onClick={onClick}
      onDragOver={handleDragOver}
      onDrop={handleDrop}
    >
      <span className={styles.banner_text}>Click to Add csv file</span>
      <span className={styles.banner_text}>Or</span>
      <span className={styles.banner_text}>Drag and Drop csv file here</span>
    </div>
  );
};

const DropZone = ({ onChange, accept = ["*"] }: {onChange: any, accept: string[]}) => {
  const inputRef = React.useRef<HTMLInputElement>(null);

  const handleClick = () => {
    inputRef.current?.click();
  };

  const handleChange = (ev: any) => {
    onChange(ev.target.files);
  };

  const handleDrop = (files: any) => {
    onChange(files);
  };

  return (
    <div className={styles.wrapper}>
      <Banner onClick={handleClick} onDrop={handleDrop} />
      <input
        type="file"
        aria-label="add files"
        className={styles.input}
        ref={inputRef}
        multiple={true}
        onChange={handleChange}
        accept={accept.join(",")}
      />
    </div>
  );
};

DropZone.propTypes = {
  accept: array,
  onChange: func,
};

export { DropZone };
