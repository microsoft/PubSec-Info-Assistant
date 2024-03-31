// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { Outlet, NavLink, Link } from "react-router-dom";

import openai from "../../assets/openai.svg";
import { WarningBanner } from "../../components/WarningBanner/WarningBanner";
import { useRef, useState, useEffect } from "react";
import { Panel, DefaultButton} from "@fluentui/react";
import styles from "./Layout.module.css";
import { Title } from "../../components/Title/Title";
import { ChatButton } from "../../components/ChatButton";
import { ModalChat } from "../../components/ModalChat";

const Layout = () => {
    const [isInfoPanelOpen, setIsInfoPanelOpen] = useState(false);
    return (
        <div className={styles.layout}>
            <header className={styles.header} role={"banner"}>
                <WarningBanner />
                <div className={styles.headerContainer}>
                    <div className={styles.headerTitleContainer}>
                        <img src={openai} alt="Azure OpenAI" className={styles.headerLogo} />
                        <h3 className={styles.headerTitle}><Title/></h3>
                    </div>
                    <nav>
                        <ul className={styles.headerNavList}>
                            <li>
                                <NavLink to="/" className={({ isActive }) => (isActive ? styles.headerNavPageLinkActive : styles.headerNavPageLink)}>
                                    Home
                                </NavLink>
                            </li>
                            <li className={styles.headerNavLeftMargin}>
                                <NavLink to="/chat" className={({ isActive }) => (isActive ? styles.headerNavPageLinkActive : styles.headerNavPageLink)}>
                                    Chat
                                </NavLink>
                            </li>
                        </ul>
                    </nav>
                </div>
            </header>
            <div className={styles.raibanner}>
                <span className={styles.raiwarning}>AI-generated content may be incorrect</span>
            </div>

            <Outlet />

            <div className={styles.chatButton}>
                <ChatButton className={styles.commandButton} onClick={() => setIsInfoPanelOpen(!isInfoPanelOpen)} />
            </div>
            <Panel
                headerText="Modal Chat"
                isOpen={isInfoPanelOpen}
                isBlocking={false}
                onDismiss={() => setIsInfoPanelOpen(false)}
                closeButtonAriaLabel="Close"
                className={styles.modalchatpanel}
                onRenderFooterContent={() => <DefaultButton onClick={() => setIsInfoPanelOpen(false)}>Close</DefaultButton>}
                isFooterAtBottom={true}                >
                    <div id="modalChatMain">
                        <ModalChat/>
                    </div>
            </Panel>
            <footer>
                <WarningBanner />
            </footer>
        </div>
    );
};

export default Layout;
