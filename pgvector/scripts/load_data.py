import openai

client = openai.OpenAI()

def get_embedding(text: str):
    """Generate embedding using OpenAI API"""
    response = client.embeddings.create(
        model="text-embedding-3-small",
        input=text
    )
    return response.data[0].embedding

def load_books_to_db():
    """Load books with embeddings into PostgreSQL"""

    # 1. Fetches books from Open Library API
    books = fetch_books()

    for book in books:
        # 2.Create text description for embedding
        description = f"Book titled '{book['title']}' by {', '.join(book['authors'])}. "
        description += f"Published in {book['first_publish_year']}. "
        description += f"This is a book about {book['subject']}."

        # 3. Generate embedding using OpenAI
        embedding = get_embedding(description)

        # 4. Stores books and embeddings in PostgreSQL
        store_book(book["title"], json.dumps(book), embedding)
