// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { Text } from "@fluentui/react";
import { Label } from '@fluentui/react/lib/Label';

interface Props {
    className?: string;
    item?: any;
}
interface Stat {
    status: string; // replace 'string' with the actual type of 'timestamp'
    // include other properties of 'stat' here
}
export const StatusContent = ({ item }: Props) => {
    const data = item.status_updates.reverse();
    const DisplayData = data.map((stat: string, index: number) => {
        return (
            <tr key={index}>
                <td>{typeof stat === 'string' ? stat : JSON.stringify(stat)}</td>
            </tr>
        );
    });
    
    return (
        <div>
            <Label>File Name</Label><Text>{item?.name}</Text>
            <table className="table table-striped">
                <thead>
                    <tr>
                    <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    {DisplayData}
                </tbody>
            </table>
        </div>
    );
};