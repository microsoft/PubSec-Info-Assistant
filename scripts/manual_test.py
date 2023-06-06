import status_log as status_log
import argparse


parser = argparse.ArgumentParser(
    description="Upsert a status log entry for processing a file.",
    epilog="Example: upsert-status.py --url url --key key --database_name database_name --container_name container_name --json_document json_document -v"
    )
parser.add_argument("--url", help="endpoint of the cosmos db instance")
parser.add_argument("--key", help="key to access the cosmosdb instance")
parser.add_argument("--database_name", help="name of the cosmos db database")
parser.add_argument("--container_name", help="name of the cosmos db container")
parser.add_argument("--document_id", help="the document id to upsert")
parser.add_argument("--status", help="status snpashot")
parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")
args = parser.parse_args()


if __name__ == "__main__":
    
    status_log.upsert_document(args.url, args.key, args.database_name, args.container_name, 'asdfasdf', args.status)
