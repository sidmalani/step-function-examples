def test(event, context):
    print("Test called")
    event["oranges"] = "1"
    return event
