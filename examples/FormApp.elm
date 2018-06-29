module FormApp exposing (..)

import Date exposing (Date, Day(..), Month(..))
import Date.Format
import DatePicker exposing (DatePicker)
import Html exposing (..)
import Html.Attributes exposing (..)
import Prima.Form as Form
    exposing
        ( FormField
        , FormFieldConfig
        , Validation(..)
        )
import Task
import Tuple


type alias Model =
    { userName : Maybe String
    , gender : Maybe String
    , city : Maybe String
    , privacy : Bool
    , dateOfBirth : Maybe Date
    , dateOfBirthDP : Maybe DatePicker
    , country : Maybe String
    , countryFilter : Maybe String
    }


initialModel : Model
initialModel =
    Model
        Nothing
        Nothing
        Nothing
        False
        Nothing
        Nothing
        Nothing
        Nothing


type FieldName
    = Privacy
    | Gender
    | UserName
    | City
    | DateOfBirth
    | Country


type Msg
    = UpdateField FieldName (Maybe String)
    | UpdateAutocomplete FieldName (Maybe String)
    | UpdateDate FieldName DatePicker.Msg
    | UpdateFlag FieldName Bool
    | FetchDateToday Date


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.batch []
        }


fetchDateToday : Cmd Msg
fetchDateToday =
    Task.perform FetchDateToday Date.now


init : ( Model, Cmd Msg )
init =
    let
        ( dateOfBirthDP, dpCmd ) =
            DatePicker.init
    in
    { initialModel
        | dateOfBirthDP = Just dateOfBirthDP
    }
        ! [ fetchDateToday
          , Cmd.map (UpdateDate DateOfBirth) dpCmd
          ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FetchDateToday date ->
            { model | dateOfBirth = Just date } ! []

        UpdateField UserName value ->
            { model | userName = value } ! []

        UpdateField Gender value ->
            { model | gender = value } ! []

        UpdateField City value ->
            { model | city = value } ! []

        UpdateFlag Privacy value ->
            { model | privacy = value } ! []

        UpdateField Country value ->
            { model | country = value } ! []

        UpdateDate DateOfBirth dpMsg ->
            let
                ( dateOfBirthInitialDP, _ ) =
                    DatePicker.init

                ( updatedDP, dpCmd, dateEvent ) =
                    DatePicker.update
                        datepickerSettings
                        dpMsg
                        (case model.dateOfBirthDP of
                            Just dateOfBirthDP ->
                                dateOfBirthDP

                            Nothing ->
                                dateOfBirthInitialDP
                        )

                date =
                    case dateEvent of
                        DatePicker.NoChange ->
                            model.dateOfBirth

                        DatePicker.Changed chosenDate ->
                            chosenDate
            in
            { model
                | dateOfBirth = date
                , dateOfBirthDP = Just updatedDP
            }
                ! [ Cmd.map (UpdateDate DateOfBirth) dpCmd ]

        UpdateAutocomplete Country value ->
            { model | countryFilter = value } ! []

        _ ->
            model ! []


userNameConfig : FormField Model Msg
userNameConfig =
    Form.textConfig
        "user_name"
        "User name"
        False
        [ maxlength 3 ]
        .userName
        (UpdateField UserName)
        [ NotEmpty ]


genderConfig : FormField Model Msg
genderConfig =
    Form.radioConfig
        "gender"
        "Gender"
        False
        []
        .gender
        (UpdateField Gender)
        [ ( "Male", "male" ), ( "Female", "female" ) ]
        [ NotEmpty ]


privacyConfig : FormField Model Msg
privacyConfig =
    Form.checkboxConfig
        "privacy"
        "Privacy"
        False
        []
        .privacy
        (UpdateFlag Privacy)
        []


cityConfig : FormField Model Msg
cityConfig =
    Form.selectConfig
        "city"
        "City"
        False
        []
        .city
        (UpdateField City)
        (List.sortBy Tuple.first
            [ ( "Milano", "MI" )
            , ( "Torino", "TO" )
            , ( "Roma", "RO" )
            , ( "Napoli", "NA" )
            , ( "Genova", "GE" )
            ]
        )
        True
        [ NotEmpty ]


dateOfBirthConfig : DatePicker -> FormField Model Msg
dateOfBirthConfig datepicker =
    Form.datepickerConfig
        "date_of_birth"
        "Date of Birth"
        False
        .dateOfBirth
        (UpdateDate DateOfBirth)
        datepicker
        datepickerSettings
        []


countryConfig : Model -> FormField Model Msg
countryConfig { countryFilter } =
    let
        lowerFilter =
            (String.toLower << Maybe.withDefault "") countryFilter
    in
    Form.autocompleteConfig
        "country"
        "Country"
        False
        []
        .countryFilter
        .country
        (UpdateAutocomplete Country)
        (UpdateField Country)
        ([ ( "Italy", "ITA" )
         , ( "Brasil", "BRA" )
         , ( "France", "FRA" )
         , ( "England", "ENG" )
         , ( "USA", "USA" )
         , ( "Japan", "JAP" )
         ]
            |> List.filter (String.contains lowerFilter << String.toLower << Tuple.first)
        )
        [ NotEmpty ]


view : Model -> Html Msg
view model =
    div
        [ class "a-container a-container--small" ]
        [ Form.render model userNameConfig
        , Form.render model genderConfig
        , Form.render model privacyConfig
        , Form.render model cityConfig
        , renderOrNothing (Maybe.map (Form.render model << dateOfBirthConfig) model.dateOfBirthDP)
        , Form.render model (countryConfig model)
        ]


renderOrNothing : Maybe (Html a) -> Html a
renderOrNothing maybeHtml =
    Maybe.withDefault (text "") maybeHtml


formatDate : String -> Maybe Date -> String
formatDate dateFormat date =
    Maybe.map (Date.Format.format dateFormat) date |> Maybe.withDefault ""


datepickerSettings : DatePicker.Settings
datepickerSettings =
    let
        settings =
            DatePicker.defaultSettings
    in
    { settings
        | dateFormatter = formatDate "%d/%m/%Y" << Just
        , dayFormatter = dayFormatter
        , monthFormatter = monthFormatter
        , firstDayOfWeek = Mon
        , inputClassList =
            [ ( "form__field__input", True )
            , ( "form__field__input--datepicker", True )
            ]
    }


dayFormatter : Day -> String
dayFormatter day =
    case day of
        Mon ->
            "Lun"

        Tue ->
            "Mar"

        Wed ->
            "Mer"

        Thu ->
            "Gio"

        Fri ->
            "Ven"

        Sat ->
            "Sab"

        Sun ->
            "Dom"


monthFormatter : Month -> String
monthFormatter month =
    case month of
        Jan ->
            "Gennaio"

        Feb ->
            "Febbraio"

        Mar ->
            "Marzo"

        Apr ->
            "Aprile"

        May ->
            "Maggio"

        Jun ->
            "Giugno"

        Jul ->
            "Luglio"

        Aug ->
            "Agosto"

        Sep ->
            "Settembre"

        Oct ->
            "Ottobre"

        Nov ->
            "Novembre"

        Dec ->
            "Dicembre"
