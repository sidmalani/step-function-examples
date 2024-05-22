def test(event, context):
    print("Test called")
    event["apples"] = "1"
    return event
