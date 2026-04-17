from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
from .database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    name = Column(String, nullable=False)
    hashed_password = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    contacts = relationship("Contact", back_populates="owner", cascade="all, delete-orphan")


class Contact(Base):
    __tablename__ = "contacts"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    company_name = Column(String, nullable=True)
    client_name = Column(String, nullable=True)
    business_model = Column(Text, nullable=True)
    business_operation = Column(Text, nullable=True)
    target_market = Column(Text, nullable=True)
    looking_for = Column(Text, nullable=True)
    phone_number = Column(String, nullable=True)
    email = Column(String, nullable=True)
    additional_notes = Column(Text, nullable=True)
    audio_file_path = Column(String, nullable=True)
    transcription = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    owner = relationship("User", back_populates="contacts")
