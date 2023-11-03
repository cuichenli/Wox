import React, { useEffect, useImperativeHandle } from "react"
import styled from "styled-components"
import { WoxTauriHelper } from "../utils/WoxTauriHelper.ts"
import { useVisibilityChange } from "@uidotdev/usehooks"
import { WoxMessageHelper } from "../utils/WoxMessageHelper.ts"
import { WoxMessageMethodEnum } from "../enums/WoxMessageMethodEnum.ts"

export type WoxQueryBoxRefHandler = {
  changeQuery: (query: string) => void
  selectAll: () => void
  focus: () => void
  updatePlaceHolder: (placeHolder: string) => void
}

export type WoxQueryBoxProps = {
  defaultValue?: string
  onQueryChange: (query: string) => void
  onFocus?: () => void
}

export default React.forwardRef((_props: WoxQueryBoxProps, ref: React.Ref<WoxQueryBoxRefHandler>) => {
  const queryBoxRef = React.createRef<HTMLInputElement>()
  const documentVisible = useVisibilityChange()
  const [currentQuery, setCurrentQuery] = React.useState<string>("")
  const [placeHolder, setPlaceHolder] = React.useState<string>("")

  useImperativeHandle(ref, () => ({
    changeQuery: (query: string) => {
      if (queryBoxRef.current) {
        queryBoxRef.current!.value = query
        setCurrentQuery(query)
        _props.onQueryChange(query)
      }
    },
    selectAll: () => {
      queryBoxRef.current?.select()
    },
    focus: () => {
      queryBoxRef.current?.focus()
    },
    updatePlaceHolder(placeHolder: string) {
      setPlaceHolder(placeHolder)
    }
  }))

  useEffect(() => {
    // Focus on query box when document is visible
    if (documentVisible) {
      queryBoxRef.current?.focus()
      WoxMessageHelper.getInstance().sendMessage(WoxMessageMethodEnum.ON_VISIBILITY_CHANGED.code, {
        "isVisible": "true",
        "query": queryBoxRef.current?.value || ""
      })
    }
  }, [documentVisible])


  return <Style className="wox-query-box">
    <input ref={queryBoxRef}
           title={"Query Wox"}
           className={"mousetrap"}
           type="text"
           aria-label="Wox"
           autoComplete="off"
           autoCorrect="off"
           autoCapitalize="off"
           defaultValue={_props.defaultValue}
           onFocus={() => {
             _props.onFocus?.()
           }}
           onChange={(e) => {
             setCurrentQuery(e.target.value)
             _props.onQueryChange(e.target.value)
           }} />
    {currentQuery && <span className={"wox-placeholder"}>{placeHolder.split("").map((value, index) => {
      if (currentQuery && index < currentQuery.length) {
        return <span style={{ color: "transparent", padding: 0, display: "inline" }}>{value}</span>
      }
      return value
    })}</span>}
    <button className={"wox-setting"} onMouseMoveCapture={(event) => {
      WoxTauriHelper.getInstance().startDragging().then(_ => {
        queryBoxRef.current?.focus()
      })
      event.preventDefault()
      event.stopPropagation()
    }}>Wox
    </button>
  </Style>
})

const Style = styled.div`
  position: relative;
  width: ${WoxTauriHelper.getInstance().getWoxWindowWidth()}px;
  overflow: hidden;
  border: ${WoxTauriHelper.getInstance().isTauri() ? "0px" : "1px"} solid #dedede;

  input {
    height: 59px;
    line-height: 59px;
    width: ${WoxTauriHelper.getInstance().getWoxWindowWidth()}px;
    font-size: 24px;
    outline: none;
    padding: 10px;
    border: 0;
    background-color: transparent;
    cursor: auto;
    color: black;
    display: inline-block;
  }

  .wox-placeholder {
    position: absolute;
    left: 7px;
    top: 11px;
    font-size: 24px;
    color: #545454;
  }

  .wox-setting {
    position: absolute;
    bottom: 3px;
    right: 4px;
    top: 3px;
    padding: 0 10px;
    background: transparent;
    border: none;
    color: #545454;
  }
`