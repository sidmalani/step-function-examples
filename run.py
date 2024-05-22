import tkinter as tk
from tkinter import ttk
import boto3
import json
import time

sqs = boto3.client('sqs', region_name='ap-southeast-2')
step_functions = boto3.client('stepfunctions', region_name='ap-southeast-2')
queue_url = '<QUEUE_URL>'

def update_table():
    response = {}

    while "Messages" not in response:
        response = sqs.receive_message(
            QueueUrl=queue_url,
            AttributeNames=[
                'SentTimestamp'
            ],
            MaxNumberOfMessages=1,
            MessageAttributeNames=[
                'All'
            ]
        )
        time.sleep(5)
        print("waiting for response")

    print(f"Response {response}")
    if 'Messages' in response and len(response['Messages']) > 0:
        message = response['Messages'][0]
        receipt_handle = message['ReceiptHandle']

        # Delete received message from queue
        sqs.delete_message(
            QueueUrl=queue_url,
            ReceiptHandle=receipt_handle
        )

        obj = json.loads(message['Body'])
        print(obj)

        item=(obj["MessageTitle"], obj["TaskToken"], "")
        tree.insert("", "end", values=item)


def process_record():
    curItem = tree.focus()
    obj = tree.item(curItem)
    print(f"obj {obj}")
    print(f"token {obj['values'][1]}")
    step_functions.send_task_success(
        taskToken=obj['values'][1],
        output=json.dumps({"Successfully processed": f"{obj['values'][0]}"})
    )
    tree.delete(curItem)

def delete_record():
    curItem = tree.focus()
    tree.delete(curItem)


root = tk.Tk()
root.title("Dynamic Table with Tkinter")
columns = ("Order ID", "", "")
tree = ttk.Treeview(root, columns=columns, show='headings')

for col in columns:
    tree.heading(col, text=col)
    tree.column(col, width=100)

tree.pack(pady=20)
update_button = tk.Button(root, text="Refresh Table", command=lambda: update_table())
update_button.pack(pady=20)
process_button = tk.Button(root, text="Process Order", command=lambda: process_record())
process_button.pack(pady=20)
delete_button = tk.Button(root, text="Delete Order", command=lambda: delete_record())
delete_button.pack(pady=20)

# Run the main Tkinter loop
root.mainloop()

