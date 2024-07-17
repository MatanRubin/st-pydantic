from typing import List

import streamlit as st
from pydantic import BaseModel, Field, SecretStr

import st_pydantic as sp


class SubModel(BaseModel):
    things_i_like: List[str]


class MySettings(sp.StreamlitSettings):
    username: str = Field(..., description="The username for the database.")
    password: SecretStr
    my_cool_secrets: SubModel


st.json(MySettings().dict())
